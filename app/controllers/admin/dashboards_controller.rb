class Admin::DashboardsController < Admin::AdminController
  def cashiers_dashboard
    cashier_ids = Cashier.pluck(:id)

    @cashier_shifts = CashierShift
      .includes([ :cashier, :opened_by, :closed_by ])
      .joins(:cashier)
      .where(id: CashierShift
        .where(cashier_id: cashier_ids)
        .select("DISTINCT ON (cashier_id) id")
        .order("cashier_id, created_at DESC")
      )
      .order(
        Arel.sql("CASE cashiers.cashier_type
                  WHEN 0 THEN 1
                  WHEN 1 THEN 2
                  ELSE 3 END"),
        id: :desc
      )
  end

  def sales_dashboard
    @selected_location = @current_location

    set_sales_variables
    set_chart_data
    set_seller_commissions_monthly_list
  end

  def sales_ranking
    @current_period = SellerBiweeklySalesTarget.current_year_month_period
    seller_biweekly_sales_targets = SellerBiweeklySalesTarget.where(year_month_period: @current_period)
    if seller_biweekly_sales_targets.blank?
      @current_period = SellerBiweeklySalesTarget.previous_year_month_period
      seller_biweekly_sales_targets = SellerBiweeklySalesTarget.where(year_month_period: @current_period)
    end
    start_date, end_date = SellerBiweeklySalesTarget.period_date_range(@current_period)

    @ranking = User.includes(:user_seller_photo)
      .with_any_role("seller", "supervisor", "store_manager")
      .where(status: "active")
      .joins(sanitize_sql_array([ <<-SQL, start_date, end_date, @current_period ]))
        LEFT JOIN (
          SELECT#{' '}
            commissions.user_id,
            SUM(commissions.sale_amount_cents) as total_sales_cents
          FROM commissions
          LEFT JOIN orders ON orders.id = commissions.order_id
          WHERE orders.order_date BETWEEN ? AND ?
          AND orders.status = 0
          GROUP BY commissions.user_id
        ) as commission_totals ON commission_totals.user_id = users.id
        LEFT JOIN (
          SELECT#{' '}
            seller_id,
            SUM(sales_target_cents) as total_target_cents
          FROM seller_biweekly_sales_targets
          WHERE year_month_period = ?
          GROUP BY seller_id
        ) as target_totals ON target_totals.seller_id = users.id
      SQL
      .select(
        "users.*",
        "commission_totals.total_sales_cents",
        "target_totals.total_target_cents",
        "CASE
          WHEN COALESCE(target_totals.total_target_cents, 0) > 0
          THEN (COALESCE(commission_totals.total_sales_cents, 0)::float / COALESCE(target_totals.total_target_cents, 0)) * 100
          ELSE 0
        END as achievement_percentage"
      )
      .group(
        "users.id",
        "commission_totals.total_sales_cents",
        "target_totals.total_target_cents"
      )
      .order("achievement_percentage DESC")
      .map do |user|
        data = {
          id: user.id,
          name: user.name,
          photo_url: user.user_seller_photo&.seller_photo,
          total_sales: Money.new(user.total_sales_cents || 0, "PEN"),
          total_target: Money.new(user.total_target_cents || 0, "PEN"),
          achievement_percentage: user.achievement_percentage&.round(2) || 0
        }
        Rails.logger.info "Seller Data: #{data.inspect}"
        data
      end
  end

  def set_location
    return head :forbidden unless current_user.any_admin_or_supervisor?

    location_id = params[:location_id]

    if location_id.present? && location_id != ""
      session[:location_id] = location_id
      @selected_location = Location.find_by(id: location_id)
      @selected_location_name = @selected_location ? @selected_location.name : "Todas"
    else
      session.delete(:location_id)
      @selected_location = nil
      @selected_location_name = "Todas"
    end

    set_sales_variables
    set_chart_data
    set_seller_commissions_monthly_list

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("sales_count", partial: "sales_count"),
          turbo_stream.replace("sales_amount", partial: "sales_amount"),
          turbo_stream.replace("sales_count_this_month", partial: "sales_count_this_month"),
          turbo_stream.replace("sales_amount_this_month", partial: "sales_amount_this_month"),
          turbo_stream.replace("sales_average_per_day_this_month", partial: "sales_average_per_day_this_month"),
          turbo_stream.replace("sales_dashboard_notification_feed", partial: "sales_dashboard_notification_feed"),
          turbo_stream.replace("commission_targets_graph", partial: "commission_targets_graph"),
          turbo_stream.replace("seller_commissions_list", partial: "seller_commissions_list")
        ]
      end
    end
  end

  private

    def set_sales_variables
      set_sales_count_variables
      set_sales_amount_variables
      set_sales_amount_this_month_variables
      set_sales_count_this_month_variables
      set_sales_daily_average_this_month_variables
    end

    def set_seller_commissions_list
      if @selected_location.present?
        @seller_commissions_list = Commission.joins(:order).includes(order: {}).where(orders: { location_id: @selected_location&.id }).order(created_at: :desc).limit(5)
      else
        @seller_commissions_list = Commission.all.includes(order: {}).order(created_at: :desc).limit(5)
      end
    end

    def set_seller_commissions_monthly_list
      current_month_range = Time.zone.now.beginning_of_month..Time.zone.now.end_of_month

      base_query = User.joins(:commissions)
                      .joins("INNER JOIN orders ON orders.id = commissions.order_id")
                      .where(orders: { order_date: current_month_range })
                      .group("users.id")
                      .select("users.*, SUM(commissions.sale_amount_cents) as total_commission_cents")
                      .order("total_commission_cents DESC")

      @seller_commissions_list = if @selected_location.present?
        base_query.where(orders: { location_id: @selected_location.id })
      else
        base_query
      end
    end

    def sanitize_sql_array(array)
      ActiveRecord::Base.send(:sanitize_sql_array, array)
    end

    def set_chart_data
      if @selected_location.present?
        @commission_ranges = CommissionRange.where(location_id: @selected_location.id).order(:min_sales)

        start_date = Date.current.beginning_of_month
        end_date = Date.current + 1.day

        orders = filtered_orders.where(order_date: start_date..end_date)
        daily_sales = orders.map { |order| [ order.order_date.to_date, order.total_price_cents ] }
                    .group_by { |date, _| date }
                    .transform_values { |vals| vals.sum { |_, price| price } }

        cumulative_sales = []
        daily_bars = []
        running_total = 0

        daily_sales.sort.each do |date, cents|
          sales = (cents / 100.0).round(2)
          running_total += sales
          timestamp = date.to_time.to_i * 1000
          cumulative_sales << { x: timestamp, y: running_total }
          daily_bars << { x: timestamp, y: sales }  # Changed to show daily sales
        end

        max_commission_range = @commission_ranges.map { |range| range.max_sales || range.min_sales }.max
        max_sales = [ cumulative_sales.last&.dig(:y) || 0, max_commission_range || 0 ].max
        max_y_axis = (max_sales * 1.1).round(-2) # 10% higher than the max value, rounded to nearest 100

        @team_goals = {
          series: [
            {
              name: "Ventas diarias",
              type: "column",
              data: daily_bars
            },
            {
              name: "Ventas diarias acumuladas",
              type: "line",
              data: cumulative_sales
            }
          ],
          annotations: {
            yaxis: @commission_ranges.map do |range|
              target_value = (range.max_sales || range.min_sales * 1.2).round(2)
              {
                y: target_value,
                borderColor: "#00E396",
                label: {
                  borderColor: "#00E396",
                  style: { color: "#fff", background: "#00E396" },
                  text: "Comisión #{range.commission_percentage}%"
                }
              }
            end
          },
          maxYAxis: max_y_axis
        }
      else
        @team_goals = { series: [], annotations: { yaxis: [] }, maxYAxis: 1000 }
      end
    end

    def generate_color(index)
      # Generate a color based on the index
      hue = (index * 137.5) % 360
      "hsl(#{hue}, 70%, 50%)"
    end

    def set_sales_count_variables
      @sales_count = filtered_orders.where(order_date: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day).count
      sales_count_yesterday = filtered_orders.where(order_date: 1.day.ago.beginning_of_day..1.day.ago.end_of_day).count || 0
      sales_count_change_since_yesterday = @sales_count - sales_count_yesterday
      @sales_count_change_since_yesterday = format_change(sales_count_change_since_yesterday)

      sales_count_last_month = filtered_orders.where(order_date: 1.month.ago.beginning_of_day..1.month.ago.end_of_day).count || 0
      sales_count_change_since_last_month = @sales_count - sales_count_last_month
      @sales_count_change_since_last_month = format_change(sales_count_change_since_last_month)
    end

    def set_sales_amount_variables
      @sales_amount = (filtered_orders.where(order_date: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day).sum(:total_price_cents) / 100.0).round(2)
      sales_amount_yesterday = (filtered_orders.where(order_date: 1.day.ago.beginning_of_day..1.day.ago.end_of_day).sum(:total_price_cents) / 100.0 || 0).round(2)
      sales_amount_change_since_yesterday = @sales_amount - sales_amount_yesterday
      @sales_amount_change_since_yesterday = format_change(sales_amount_change_since_yesterday)

      sales_amount_last_month = (filtered_orders.where(order_date: 1.month.ago.beginning_of_day..1.month.ago.end_of_day).sum(:total_price_cents) / 100.0 || 0).round(2)
      sales_amount_change_since_last_month = @sales_amount - sales_amount_last_month
      @sales_amount_change_since_last_month = format_change(sales_amount_change_since_last_month)
    end

    def set_sales_amount_this_month_variables
      Rails.logger.info("Setting sales amount this month variables")
      # Get current date and time
      current_time = Time.zone.now
      
      # Calculate the same day and time for last month
      same_time_last_month = current_time.prev_month
      
      # Get sales for current month up to now
      @sales_amount_this_month = (filtered_orders.where(order_date: current_time.beginning_of_month..current_time).sum(:total_price_cents) / 100.0).round(2)
      
      # Get sales for last month up to the same day and time
      @sales_amount_last_month = (filtered_orders.where(order_date: same_time_last_month.beginning_of_month..same_time_last_month).sum(:total_price_cents) / 100.0 || 0).round(2)
      
      @sales_amount_change_since_last_month = @sales_amount_this_month - @sales_amount_last_month
      @sales_amount_change_since_last_month = format_change(@sales_amount_change_since_last_month)
      @sales_amount_change_since_last_month_percentage = calculate_percentage_change(@sales_amount_this_month, @sales_amount_last_month)
    end

    def set_sales_count_this_month_variables
      Rails.logger.info("Setting sales count this month variables")
      # Get current date and time
      current_time = Time.zone.now
      
      # Calculate the same day and time for last month
      same_time_last_month = current_time.prev_month
      
      # Get sales count for current month up to now
      @sales_count_this_month = filtered_orders.where(order_date: current_time.beginning_of_month..current_time).count
      
      # Get sales count for last month up to the same day and time
      @sales_count_last_month = filtered_orders.where(order_date: same_time_last_month.beginning_of_month..same_time_last_month).count
      
      @sales_count_change_since_last_month = @sales_count_this_month - @sales_count_last_month
      @sales_count_change_since_last_month_percentage = calculate_percentage_change(@sales_count_this_month, @sales_count_last_month)
    end

    def set_sales_daily_average_this_month_variables
      Rails.logger.info("Setting sales daily average variables")
      days_so_far_this_month = Time.zone.now.day
      days_last_month = Time.days_in_month(1.month.ago.month)

      sales_amount_this_month = (filtered_orders.where(order_date: Time.zone.now.beginning_of_month..Time.zone.now.end_of_month).sum(:total_price_cents) / 100.0).round(2)
      sales_amount_last_month = (filtered_orders.where(order_date: 1.month.ago.beginning_of_month..1.month.ago.end_of_month).sum(:total_price_cents) / 100.0 || 0).round(2)

      @sales_daily_average_this_month = (sales_amount_this_month / days_so_far_this_month).round(2)
      @sales_daily_average_last_month = (sales_amount_last_month / days_last_month).round(2)
      @sales_daily_average_change_since_last_month = (@sales_daily_average_this_month - @sales_daily_average_last_month).round(2)
      @sales_daily_average_change_since_last_month = format_change(@sales_daily_average_change_since_last_month)
    end

    def filtered_orders
      if @selected_location.blank?
        Order.all
      else
        @selected_location.orders
      end
    end

    def format_change(value)
      if value.blank?
        "+0"
      else
        if value.is_a?(Integer) || value.is_a?(Float)
          value >= 0 ? "+#{value.round(2)}" : "#{value.round(2)}"
        else
          if value.to_f >= 0
            "+#{value.to_f}%"
          else
            "#{value.to_f}%"
          end
        end
      end
    end

    def calculate_percentage_change(new_value, old_value)
      return "0%" if old_value.zero?
      percentage = ((new_value - old_value) / old_value) * 100
      format_change("#{percentage.round(2)}%")
    end
end
