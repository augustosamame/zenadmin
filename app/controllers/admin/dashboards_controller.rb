class Admin::DashboardsController < Admin::AdminController
  def sales_dashboard
    @locations = Location.active.order(:name).pluck(:id, :name)
    @selected_location_id = session[:location_id]
    if @selected_location_id.present?
      @selected_location = Location.find_by(id: @selected_location_id)
      @selected_location_name = @selected_location ? @selected_location.name : "Todas"
    else
      @selected_location = nil
      @selected_location_name = "Todas"
    end
    set_sales_variables
    set_chart_data
    Rails.logger.debug "Company Goals: #{@company_goals.inspect}"
  end

  def set_location
    @locations = Location.active.order(:name).pluck(:id, :name)
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

    Rails.logger.debug "Company Goals: #{@company_goals.inspect}"

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("sales_count", partial: "sales_count"),
          turbo_stream.replace("sales_amount", partial: "sales_amount"),
          turbo_stream.replace("sales_amount_this_month", partial: "sales_amount_this_month"),
          turbo_stream.replace("sales_average_per_day_this_month", partial: "sales_average_per_day_this_month"),
          turbo_stream.replace("sales_dashboard_notification_feed", partial: "sales_dashboard_notification_feed"),
          turbo_stream.replace("commission_targets_graph", partial: "commission_targets_graph")

        ]
      end
      format.html { redirect_to admin_sales_dashboard_path }
    end
  end

  private

    def set_sales_variables
      set_sales_count_variables
      set_sales_amount_variables
      set_sales_amount_this_month_variables
      set_sales_daily_average_this_month_variables
    end

    def set_chart_data
      if @selected_location.present?
        @commission_ranges = CommissionRange.where(location_id: @selected_location.id).order(:min_sales)

        start_date = Date.today.beginning_of_month
        end_date = Date.today

        daily_sales = filtered_orders.where(order_date: start_date..end_date)
                                    .group("DATE(order_date)")
                                    .sum(:total_price_cents)

        cumulative_sales = []
        daily_bars = []
        running_total = 0

        daily_sales.sort.each do |date, cents|
          sales = (cents / 100.0).round(2)
          running_total += sales
          timestamp = date.to_time.to_i * 1000
          cumulative_sales << { x: timestamp, y: running_total }
          daily_bars << { x: timestamp, y: running_total }
        end

        max_commission_range = @commission_ranges.map { |range| range.max_sales || range.min_sales * 2 }.max
        max_sales = [ cumulative_sales.last&.dig(:y) || 0, max_commission_range || 0 ].max
        max_y_axis = (max_sales * 1.1).round(-2) # 10% higher than the max value, rounded to nearest 100

        @team_goals = {
          series: [
            {
              name: "Ventas diarias acumuladas",
              type: "column",
              data: daily_bars
            },
            {
              name: "Ventas acumuladas",
              type: "line",
              data: cumulative_sales
            }
          ],
          annotations: {
            yaxis: @commission_ranges.map do |range|
              target_value = (range.max_sales || range.min_sales * 2).round(2)
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
      @sales_amount = filtered_orders.where(order_date: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day).sum(:total_price_cents) / 100.0
      sales_amount_yesterday = filtered_orders.where(order_date: 1.day.ago.beginning_of_day..1.day.ago.end_of_day).sum(:total_price_cents) / 100.0 || 0
      sales_amount_change_since_yesterday = @sales_amount - sales_amount_yesterday
      @sales_amount_change_since_yesterday = format_change(sales_amount_change_since_yesterday)

      sales_amount_last_month = filtered_orders.where(order_date: 1.month.ago.beginning_of_day..1.month.ago.end_of_day).sum(:total_price_cents) / 100.0 || 0
      sales_amount_change_since_last_month = @sales_amount - sales_amount_last_month
      @sales_amount_change_since_last_month = format_change(sales_amount_change_since_last_month)
    end

    def set_sales_amount_this_month_variables
      Rails.logger.info("Setting sales amount this month variables")
      @sales_amount_this_month = filtered_orders.where(order_date: Time.zone.now.beginning_of_month..Time.zone.now.end_of_month).sum(:total_price_cents) / 100.0
      @sales_amount_last_month = filtered_orders.where(order_date: 1.month.ago.beginning_of_month..1.month.ago.end_of_month).sum(:total_price_cents) / 100.0 || 0
      @sales_amount_change_since_last_month = @sales_amount_this_month - @sales_amount_last_month
      @sales_amount_change_since_last_month = format_change(@sales_amount_change_since_last_month)
      @sales_amount_change_since_last_month_percentage = calculate_percentage_change(@sales_amount_this_month, @sales_amount_last_month)
    end

    def set_sales_daily_average_this_month_variables
      Rails.logger.info("Setting sales daily average variables")
      days_this_month = Time.days_in_month(Time.zone.now.month)
      days_last_month = Time.days_in_month(1.month.ago.month)

      sales_amount_this_month = filtered_orders.where(order_date: Time.zone.now.beginning_of_month..Time.zone.now.end_of_month).sum(:total_price_cents) / 100.0
      sales_amount_last_month = filtered_orders.where(order_date: 1.month.ago.beginning_of_month..1.month.ago.end_of_month).sum(:total_price_cents) / 100.0

      @sales_daily_average_this_month = (sales_amount_this_month / days_this_month).round(2)
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
          value >= 0 ? "+#{value}" : "#{value}"
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
