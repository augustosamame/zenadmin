class Admin::DashboardsController < Admin::AdminController
  before_action :set_selected_location, only: [ :sales_dashboard, :set_location ]
  before_action :set_locations, only: [ :sales_dashboard, :set_location ]

  def sales_dashboard
    set_sales_variables
  end

  def set_location
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

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("sales_count", partial: "sales_count"),
          turbo_stream.replace("sales_amount", partial: "sales_amount"),
          turbo_stream.replace("sales_amount_this_month", partial: "sales_amount_this_month"),
          turbo_stream.replace("sales_average_per_day_this_month", partial: "sales_average_per_day_this_month"),
          turbo_stream.replace("sales_dashboard_notification_feed", partial: "sales_dashboard_notification_feed")
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

    def set_selected_location
      @selected_location_id = session[:location_id]
      if @selected_location_id.present?
        @selected_location = Location.find_by(id: @selected_location_id)
        @selected_location_name = @selected_location ? @selected_location.name : "Todas"
      else
        @selected_location = nil
        @selected_location_name = "Todas"
      end
    end

    def set_locations
      @locations = Location.active.order(:name).pluck(:id, :name)
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

      @sales_daily_average_this_month = sales_amount_this_month / days_this_month
      @sales_daily_average_last_month = sales_amount_last_month / days_last_month
      @sales_daily_average_change_since_last_month = @sales_daily_average_this_month - @sales_daily_average_last_month
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
      value >= 0 ? "+#{value}" : value.to_s
    end

    def calculate_percentage_change(new_value, old_value)
      return "0%" if old_value.zero?
      percentage = ((new_value - old_value) / old_value) * 100
      format_change("#{percentage.round(2)}%")
    end
end
