class Admin::FlatCommissionProductsReportController < Admin::AdminController
  def index
    # Check if the feature flag is enabled
    unless $global_settings[:feature_flag_sellers_products_can_have_flat_commissions]
      redirect_to admin_root_path, alert: "Esta funcionalidad no está habilitada."
      return
    end

    # Check if this is a "Quitar Filtros" request (no filter params)
    reset_filters = params[:filter].nil? && params[:filterParams].nil? && !params[:filter].is_a?(String)

    if reset_filters
      # Clear all session values
      session.delete(:flat_commission_products_from_date)
      session.delete(:flat_commission_products_to_date)
      session.delete(:flat_commission_products_consolidated_by_seller)
    end

    # Extract filter parameters
    filter_params = {}

    if params[:filter].is_a?(String)
      # Handle the case where filter is a string (from location dropdown)
      Rails.logger.debug "Filter is a string: #{params[:filter]}"
      # Try to parse the string format "from_date VALUE to_date VALUE consolidated_by_seller VALUE"
      filter_string = params[:filter]

      # Extract from_date
      from_date_match = filter_string.match(/from_date\s+(\S+)/)
      filter_params[:from_date] = from_date_match[1] if from_date_match

      # Extract to_date
      to_date_match = filter_string.match(/to_date\s+(\S+)/)
      filter_params[:to_date] = to_date_match[1] if to_date_match

      # Extract consolidated_by_seller
      consolidated_match = filter_string.match(/consolidated_by_seller\s+(\S+)/)
      filter_params[:consolidated_by_seller] = consolidated_match[1] if consolidated_match
    elsif params[:filterParams].present?
      # Handle the case where parameters are in filterParams (from JavaScript)
      filter_params = params[:filterParams]
    else
      # Normal case - filter is a hash
      filter_params = params[:filter] || {}
    end

    # Set date filters from params or session
    if filter_params[:from_date].present?
      @from_date = filter_params[:from_date].to_date
      session[:flat_commission_products_from_date] = @from_date
    elsif session[:flat_commission_products_from_date].present?
      @from_date = session[:flat_commission_products_from_date]
    else
      @from_date = Date.current.beginning_of_month
      session[:flat_commission_products_from_date] = @from_date
    end

    if filter_params[:to_date].present?
      @to_date = filter_params[:to_date].to_date
      session[:flat_commission_products_to_date] = @to_date
    elsif session[:flat_commission_products_to_date].present?
      @to_date = session[:flat_commission_products_to_date]
    else
      @to_date = Date.current
      session[:flat_commission_products_to_date] = @to_date
    end

    # Handle consolidated_by_seller filter
    if filter_params.key?(:consolidated_by_seller)
      consolidated_value = filter_params[:consolidated_by_seller]
      @consolidated_by_seller = consolidated_value.to_s == "true" || consolidated_value.to_s == "1"
      session[:flat_commission_products_consolidated_by_seller] = @consolidated_by_seller
    elsif session[:flat_commission_products_consolidated_by_seller].present?
      @consolidated_by_seller = session[:flat_commission_products_consolidated_by_seller]
    else
      @consolidated_by_seller = false
      session[:flat_commission_products_consolidated_by_seller] = @consolidated_by_seller
    end

    @date_range = @from_date..@to_date

    # Set up datatable options as a string in the format expected by the JavaScript controller
    @datatable_options = "processing:true serverSide:true searching:false ordering:true resource_name:'FlatCommissionProductsReport' server_side:true date_filter:true"

    respond_to do |format|
      format.html
      format.json do
        # Get location_id from params or current_location
        location_id = params[:location_id].presence || @current_location&.id

        # Base query for orders with flat commission products
        base_query = Order.joins(:order_items)
                         .joins(:commissions)
                         .joins("INNER JOIN products ON order_items.product_id = products.id")
                         .joins("INNER JOIN users sellers ON commissions.user_id = sellers.id")
                         .joins("LEFT JOIN invoices ON orders.id = invoices.order_id")
                         .joins("INNER JOIN locations ON orders.location_id = locations.id")
                         .where("products.flat_commission = ?", true)
                         .where("products.flat_commission_percentage > ?", 0)

        # Apply date range filter
        if @date_range
          start_date = @date_range.begin.in_time_zone("America/Lima").beginning_of_day.utc
          end_date = @date_range.end.in_time_zone("America/Lima").end_of_day.utc
          base_query = base_query.where("orders.order_date BETWEEN ? AND ?", start_date, end_date)
        end

        # Apply location filter if present
        base_query = base_query.where("orders.location_id = ?", location_id) if location_id.present?

        # Select fields for the report
        if @consolidated_by_seller
          # For consolidated view, group by seller
          records = base_query
                    .select("locations.name as location_name,
                            sellers.id as seller_id,
                            CONCAT(sellers.first_name, ' ', sellers.last_name) as seller_name,
                            COUNT(DISTINCT orders.id) as order_count,
                            COUNT(DISTINCT products.id) as product_count,
                            SUM(order_items.price_cents * order_items.quantity) as total_sales_amount,
                            SUM((order_items.price_cents * order_items.quantity * products.flat_commission_percentage) / 100) as total_commission_amount")
                    .group("locations.name, sellers.id, sellers.first_name, sellers.last_name")
                    .order(order_column_sql)
        else
          # For detailed view, show each product in each order
          records = base_query
                    .select("orders.id as order_id,
                            orders.custom_id,
                            orders.order_date as order_datetime,
                            locations.name as location_name,
                            sellers.id as seller_id,
                            CONCAT(sellers.first_name, ' ', sellers.last_name) as seller_name,
                            invoices.id as invoice_id,
                            invoices.custom_id as invoice_number,
                            products.id as product_id,
                            products.name as product_name,
                            products.flat_commission_percentage,
                            order_items.quantity,
                            order_items.price_cents,
                            (order_items.price_cents * order_items.quantity) as product_total_cents,
                            ((order_items.price_cents * order_items.quantity * products.flat_commission_percentage) / 100) as commission_amount_cents")
                    .order(order_column_sql)
        end

        # Convert ActiveRecord results to OpenStruct objects for consistent handling
        if @consolidated_by_seller
          # For consolidated view
          records = records.map do |record|
            OpenStruct.new(
              location_name: record.location_name,
              seller_id: record.seller_id,
              seller_name: record.seller_name,
              order_count: record.order_count,
              product_count: record.product_count,
              total_sales_amount: record.total_sales_amount,
              total_commission_amount: record.total_commission_amount
            )
          end
        else
          # For detailed view
          records = records.map do |record|
            OpenStruct.new(
              order_id: record.order_id,
              custom_id: record.custom_id,
              order_datetime: record.order_datetime,
              location_name: record.location_name,
              seller_id: record.seller_id,
              seller_name: record.seller_name,
              invoice_id: record.invoice_id,
              invoice_number: record.invoice_number,
              product_id: record.product_id,
              product_name: record.product_name,
              flat_commission_percentage: record.flat_commission_percentage,
              quantity: record.quantity,
              price_cents: record.price_cents,
              product_total_cents: record.product_total_cents,
              commission_amount_cents: record.commission_amount_cents
            )
          end
        end

        # Get total count for pagination
        total_records = records.size

        # Apply pagination
        start = params[:start].to_i
        length = params[:length].to_i
        records = records[start, length] if length > 0

        # Format data for datatable
        data = records.map { |record| format_record_for_datatable(record) }

        # Add total row for consolidated view
        if @consolidated_by_seller && records.any?
          total_sales_amount = records.sum(&:total_sales_amount)
          total_commission_amount = records.sum(&:total_commission_amount)
          total_order_count = records.sum(&:order_count)
          total_product_count = records.sum(&:product_count)
          location_name = location_id.present? ? Location.find(location_id).name : "Todas las tiendas"

          total_row = [
            location_name,
            "TOTAL TODOS LOS VENDEDORES",
            "#{total_order_count} órdenes con #{total_product_count} productos",
            helpers.number_to_currency(total_sales_amount / 100, unit: "S/", format: "%u %n"),
            helpers.number_to_currency(total_commission_amount / 100, unit: "S/", format: "%u %n"),
            ""  # No actions for summary
          ]

          # Add to the end of the data array so it appears at the bottom
          data << total_row
        end

        render json: {
          draw: params[:draw].to_i,
          recordsTotal: total_records,
          recordsFiltered: total_records,
          data: data
        }
      end
    end
  end

  private

  def order_column_sql
    column_index = order_column.to_i
    direction = order_direction || "desc"

    if @consolidated_by_seller
      case column_index
      when 0 # Location
        "locations.name #{direction}"
      when 1 # Seller
        "seller_name #{direction}"
      when 2 # Order/Product Count
        "order_count #{direction}"
      when 3 # Total Sales Amount
        "total_sales_amount #{direction}"
      when 4 # Total Commission Amount
        "total_commission_amount #{direction}"
      else
        "total_commission_amount desc"
      end
    else
      case column_index
      when 0 # Location
        "locations.name #{direction}"
      when 1 # Order ID
        "orders.custom_id #{direction}"
      when 2 # Date
        "orders.order_date #{direction}"
      when 3 # Seller
        "seller_name #{direction}"
      when 4 # Customer
        "customer_name #{direction}"
      when 5 # Product
        "products.name #{direction}"
      when 6 # Quantity
        "order_items.quantity #{direction}"
      when 7 # Price
        "order_items.price_cents #{direction}"
      when 8 # Total
        "product_total_cents #{direction}"
      when 9 # Commission %
        "products.flat_commission_percentage #{direction}"
      when 10 # Commission Amount
        "commission_amount_cents #{direction}"
      else
        "orders.order_date desc"
      end
    end
  end

  def order_column
    if request.format.json?
      params.dig(:order, "0", :column)
    else
      params.dig(:order, "0", :column)
    end
  end

  def order_direction
    direction = params.dig(:order, "0", :dir)
    # Clean up direction regardless of request format
    cleaned_direction = direction.to_s.split(":").first if direction
    cleaned_direction
  end

  def format_record_for_datatable(record)
    # For consolidated views, show aggregated data by seller
    if @consolidated_by_seller
      [
        record.location_name,
        record.seller_name,
        "#{record.order_count} órdenes con #{record.product_count} productos",
        helpers.number_to_currency(record.total_sales_amount.to_f / 100, unit: "S/", format: "%u %n"),
        helpers.number_to_currency(record.total_commission_amount.to_f / 100, unit: "S/", format: "%u %n"),
        helpers.link_to("Ver Detalle", admin_reports_flat_commission_products_report_path(
          filter: {
            from_date: @from_date,
            to_date: @to_date,
            consolidated_by_seller: false
          },
          seller_id: record.seller_id
        ), class: "text-blue-600 hover:text-blue-800 underline")
      ]
    else
      # For detailed view, show each product in each order
      [
        record.location_name,
        record.custom_id,
        record.order_datetime ? I18n.l(record.order_datetime.in_time_zone("America/Lima"), format: :short) : "",
        record.seller_name,
        record.invoice_number.present? ? record.invoice_number : "",
        record.product_name,
        record.quantity,
        helpers.number_to_currency(record.price_cents.to_f / 100, unit: "S/", format: "%u %n"),
        helpers.number_to_currency(record.product_total_cents.to_f / 100, unit: "S/", format: "%u %n"),
        "#{record.flat_commission_percentage}%",
        helpers.number_to_currency(record.commission_amount_cents.to_f / 100, unit: "S/", format: "%u %n"),
        helpers.link_to("Ver Orden", admin_order_path(record.order_id), class: "text-blue-600 hover:text-blue-800 underline")
      ]
    end
  end
end
