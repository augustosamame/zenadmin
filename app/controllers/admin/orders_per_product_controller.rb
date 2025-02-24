class Admin::OrdersPerProductController < Admin::AdminController
  def index
    filter_params = params.fetch(:filter, {})
    if filter_params.is_a?(String)
      # Parse the filter string into a hash
      filter_hash = {}
      filter_params.split(" ").each_slice(2) do |key, value|
        filter_hash[key] = value
      end
      filter_params = filter_hash
    end

    @from_date = filter_params["from_date"].presence&.to_date || Date.current.beginning_of_month
    @to_date = filter_params["to_date"].presence&.to_date || Date.current
    @date_range = @from_date.beginning_of_day..@to_date.end_of_day

    base_query = OrderItem.joins(:order, :product)
      .joins("INNER JOIN locations ON orders.location_id = locations.id")
      .where(orders: { stage: [ :confirmed, :shipped, :delivered ] })
      .where(orders: { created_at: @date_range })

    @orders = if @current_location
      Rails.logger.debug "Filtering by current_location: #{@current_location.id}"
      base_query.where(orders: { location_id: @current_location.id })
    else
      Rails.logger.debug "No location filter applied"
      base_query
    end

    @orders = @orders.select(
      "products.name as product_name",
      "products.id as product_id", 
      "locations.name as location_name",
      "orders.created_at::date as order_date",
      "order_items.quantity as quantity",
      "order_items.price_cents as price_cents",
      "orders.custom_id as order_custom_id"
    )
    .order(order_column => order_direction)

    if params.dig("search", "value").present?
      @orders = @orders.where("products.name ILIKE ?", "%#{params.dig("search", "value")}%")
    end

    respond_to do |format|
      format.html do
        @datatable_options = "server_side:true;resource_name:'OrdersPerProduct';create_button:false;sort_1_desc:true;order_1_1:true;date_filter:true"
      end
      format.json do
        total_records = @orders.length
        start = params[:start].to_i
        length = params[:length].to_i
        @orders = @orders.limit(length).offset(start) if length > 0

        render json: format_for_datatable(@orders, total_records)
      end
    end
  end

  private

  def order_column
    columns = {
      "0" => "products.name",
      "1" => "order_items.quantity",
      "2" => "order_items.price_cents",
      "3" => "orders.created_at",
      "4" => "locations.name",
      "5" => "orders.custom_id"
    }

    col_index = params.dig(:order, "0", :column) || "0"
    columns[col_index] || "products.name"
  end

  def order_direction
    direction = params.dig(:order, "0", :dir)
    cleaned_direction = direction.to_s.split(":").first if direction
    cleaned_direction || "asc"
  end

  def format_for_datatable(records, total_records)
    {
      draw: params[:draw].to_i,
      recordsTotal: total_records,
      recordsFiltered: total_records,
      data: records.map do |record|
        {
          0 => record.product_name,
          1 => record.quantity,
          2 => Money.new(record.price_cents, "PEN").format,
          3 => record.order_date.strftime("%Y-%m-%d"),
          4 => record.location_name,
          5 => record.order_custom_id,
          DT_RowId: record.product_id
        }
      end
    }
  end
end
