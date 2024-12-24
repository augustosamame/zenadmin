class Admin::GroupedSalesController < Admin::AdminController
  def index
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current

    @selected_location = if current_user.any_admin_or_supervisor?
      location_id = params[:location_id] || session[:location_id]
      Location.find_by(id: location_id)
    else
      @current_location
    end

    base_query = Order.where(order_date: @start_date.beginning_of_day..@end_date.end_of_day)
                     .group("DATE(order_date)", "locations.id", "locations.name")
                     .joins(:location)
                     .select('DATE(order_date) as sale_date,
                             locations.id as location_id,
                             locations.name as location_name,
                             COUNT(*) as orders_count,
                             SUM(total_price_cents) as total_sales_cents')
                     .order("DATE(order_date) DESC, locations.name ASC")

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
