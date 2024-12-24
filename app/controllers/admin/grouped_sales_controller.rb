class Admin::GroupedSalesController < Admin::AdminController
  def index
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current

    # Convert dates to Lima timezone
    start_datetime = @start_date.in_time_zone("America/Lima").beginning_of_day.utc
    end_datetime = @end_date.in_time_zone("America/Lima").end_of_day.utc

    @selected_location = if current_user.any_admin_or_supervisor?
      location_id = params[:location_id] || session[:location_id]
      Location.find_by(id: location_id)
    else
      @current_location
    end

    date_in_lima = "DATE(order_date AT TIME ZONE 'UTC' AT TIME ZONE 'America/Lima')"

    base_query = Order.where(order_date: start_datetime..end_datetime)
                     .group(Arel.sql(date_in_lima),
                            "locations.id",
                            "locations.name")
                     .joins(:location)
                     .select(
                       Arel.sql("#{date_in_lima} as sale_date"),
                       "locations.id as location_id",
                       "locations.name as location_name",
                       "COUNT(*) as orders_count",
                       "SUM(total_price_cents) as total_sales_cents"
                     )
                     .order(Arel.sql("#{date_in_lima} DESC, locations.name ASC"))

    @sales_data = if current_user.any_admin_or_supervisor?
      if @selected_location.present?
        base_query.where(location_id: @selected_location.id)
      else
        base_query
      end
    else
      base_query.where(location_id: @current_location.id)
    end
  end
end
