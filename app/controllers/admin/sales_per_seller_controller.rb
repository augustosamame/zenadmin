class Admin::SalesPerSellerController < Admin::AdminController
  def index
    # Check if this is a "Quitar Filtros" request (no filter params)
    reset_filters = params[:filter].nil? && params[:filterParams].nil? && !params[:filter].is_a?(String)
    
    if reset_filters
      # Clear all session values
      session.delete(:sales_per_seller_from_date)
      session.delete(:sales_per_seller_to_date)
      session.delete(:sales_per_seller_by_seller)
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

    Rails.logger.debug "FILTER PARAMS: #{filter_params}"

    # Set date filters from params or session
    if filter_params[:from_date].present?
      @from_date = filter_params[:from_date].to_date
      session[:sales_per_seller_from_date] = @from_date
    elsif session[:sales_per_seller_from_date].present?
      @from_date = session[:sales_per_seller_from_date]
    else
      @from_date = Date.current.beginning_of_month
      session[:sales_per_seller_from_date] = @from_date
    end

    if filter_params[:to_date].present?
      @to_date = filter_params[:to_date].to_date
      session[:sales_per_seller_to_date] = @to_date
    elsif session[:sales_per_seller_to_date].present?
      @to_date = session[:sales_per_seller_to_date]
    else
      @to_date = Date.current
      session[:sales_per_seller_to_date] = @to_date
    end

    # Handle consolidated_by_seller filter
    if filter_params.key?(:consolidated_by_seller)
      consolidated_value = filter_params[:consolidated_by_seller]
      @consolidated_by_seller = consolidated_value.to_s == "true" || consolidated_value.to_s == "1"
      session[:sales_per_seller_by_seller] = @consolidated_by_seller
    elsif session[:sales_per_seller_by_seller].present?
      @consolidated_by_seller = session[:sales_per_seller_by_seller]
    else
      @consolidated_by_seller = false
      session[:sales_per_seller_by_seller] = @consolidated_by_seller
    end

    @date_range = @from_date..@to_date

    Rails.logger.debug "SESSION VALUES: from_date=#{session[:sales_per_seller_from_date]}, to_date=#{session[:sales_per_seller_to_date]}, consolidated_by_seller=#{session[:sales_per_seller_by_seller]}"
    Rails.logger.debug "INSTANCE VALUES: from_date=#{@from_date}, to_date=#{@to_date}, consolidated_by_seller=#{@consolidated_by_seller}"

    # Set up datatable options as a string in the format expected by the JavaScript controller
    @datatable_options = "processing:true serverSide:true searching:false ordering:true resource_name:'SalesPerSeller' server_side:true"

    respond_to do |format|
      format.html
      format.json do
        # Get location_id from params or current_location
        location_id = params[:location_id].presence || @current_location&.id

        # Base query for commissions with their associated orders and payments
        base_query = Commission.joins(:order)
                              .joins("LEFT JOIN users sellers ON commissions.user_id = sellers.id")
                              .joins("LEFT JOIN users customers ON orders.user_id = customers.id")
                              .joins("LEFT JOIN locations ON orders.location_id = locations.id")
                              .joins("LEFT JOIN payments ON payments.payable_id = orders.id AND payments.payable_type = 'Order'")
                              .joins("LEFT JOIN payment_methods ON payments.payment_method_id = payment_methods.id")
                              .joins("LEFT JOIN invoices ON orders.id = invoices.order_id")
                          
        # Apply date range filter using the same approach as consolidated_sales
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
                            sellers.id as user_id,
                            CONCAT(sellers.first_name, ' ', sellers.last_name) as seller_name,
                            COUNT(DISTINCT orders.id) as order_count,
                            SUM(commissions.sale_amount_cents) as order_total,
                            SUM(commissions.amount_cents) as commission_total")
                    .group("locations.name, sellers.id, sellers.first_name, sellers.last_name")
                    .order(order_column_sql)
        else
          # For detailed view, show each commission
          records = base_query
                    .select("commissions.id,
                            orders.id as order_id,
                            orders.custom_id,
                            orders.order_date as order_datetime,
                            locations.name as location_name,
                            sellers.id as user_id,
                            CONCAT(sellers.first_name, ' ', sellers.last_name) as seller_name,
                            customers.id as customer_user_id,
                            CONCAT(customers.first_name, ' ', customers.last_name) as customer_name,
                            commissions.sale_amount_cents as order_total,
                            commissions.percentage as commission_percentage,
                            commissions.amount_cents as commission_amount,
                            (commissions.sale_amount_cents * commissions.percentage / 100) as calculated_commission,
                            payment_methods.description as payment_method,
                            payments.amount_cents as payment_total,
                            payments.processor_transacion_id as payment_tx,
                            invoices.custom_id as invoice_custom_id,
                            invoices.sunat_status as invoice_status")
                    .order(order_column_sql)
        end

        # Convert ActiveRecord results to OpenStruct objects for consistent handling
        if @consolidated_by_seller
          # For consolidated view
          records = records.map do |record|
            OpenStruct.new(
              id: nil,
              user_id: record.user_id,
              location_name: record.location_name,
              custom_id: nil,
              order_datetime: nil,
              seller_name: record.seller_name,
              customer_name: nil,
              order_total: record.order_total,
              commission_total: record.commission_total,
              payment_method: nil,
              payment_total: nil,
              payment_tx: nil,
              invoice_custom_id: nil,
              invoice_url: nil,
              invoice_status: nil,
              order_count: record.order_count
            )
          end
        else
          # For detailed view
          records = records.map do |record|
            OpenStruct.new(
              id: record.id,
              order_id: record.order_id,
              location_name: record.location_name,
              custom_id: record.custom_id,
              order_datetime: record.order_datetime,
              seller_name: record.seller_name,
              customer_name: record.customer_name,
              order_total: record.order_total,
              commission_percentage: record.commission_percentage,
              commission_amount: record.commission_amount,
              calculated_commission: record.calculated_commission,
              payment_method: record.payment_method,
              payment_total: record.payment_total,
              payment_tx: record.payment_tx,
              invoice_custom_id: record.invoice_custom_id,
              invoice_url: record.invoice_custom_id.present? ? admin_invoice_path(Invoice.find_by(custom_id: record.invoice_custom_id)) : nil,
              invoice_status: record.invoice_status
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
        orders_data = records.map { |record| format_record_for_datatable(record) }

        # Add total row for consolidated view
        if @consolidated_by_seller
          total_order_amount = records.sum(&:order_total)
          total_commission_amount = records.sum(&:commission_total)
          total_count = records.sum(&:order_count)
          location_name = location_id.present? ? Location.find(location_id).name : "Todas las tiendas"

          total_row = [
            location_name,
            "", # No order ID for summary
            "", # No date for summary
            "TOTAL TODOS LOS VENDEDORES (#{total_count} ventas)",
            helpers.number_to_currency(total_order_amount / 100, unit: "S/", format: "%u %n"),
            "", # No percentage for summary
            helpers.number_to_currency(total_commission_amount / 100, unit: "S/", format: "%u %n"),
            "", # No invoice for summary
            ""  # No actions for summary
          ]

          # Add to the end of the data array so it appears at the bottom
          orders_data << total_row
        end

        render json: {
          draw: params[:draw].to_i,
          recordsTotal: total_records,
          recordsFiltered: total_records,
          data: orders_data
        }
      end
    end
  end

  private

  def order_column_sql
    column_index = order_column.to_i
    direction = order_direction || "desc"

    case column_index
    when 0 # Location
      "locations.name #{direction}"
    when 1 # Order ID
      "orders.custom_id #{direction}"
    when 2 # Date
      "orders.order_date #{direction}"
    when 3 # Seller
      "seller_name #{direction}"
    when 4 # Order Total
      "commissions.sale_amount_cents #{direction}"
    when 5 # Commission Percentage
      "commissions.percentage #{direction}"
    when 6 # Commission Amount
      "commissions.amount_cents #{direction}"
    when 7 # Payment Method
      "payment_methods.description #{direction}"
    else
      "orders.order_date desc"
    end
  end

  def order_column
    if request.format.json?
      Rails.logger.debug "JSON request - column index: #{params.dig(:order, '0', :column)}"
      params.dig(:order, "0", :column)
    else
      Rails.logger.debug "HTML request - column index: #{params.dig(:order, '0', :column)}"
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
        "", # No order ID for consolidated view
        "", # No date for consolidated view
        record.seller_name,
        helpers.number_to_currency(record.order_total.to_f / 100, unit: "S/", format: "%u %n"),
        "", # No percentage for consolidated view
        helpers.number_to_currency(record.commission_total.to_f / 100, unit: "S/", format: "%u %n"),
        "", # No invoice for consolidated view
        ""  # No actions for consolidated view
      ]
    else
      # For detailed view, show each commission
      [
        record.location_name,
        record.custom_id,
        record.order_datetime ? I18n.l(record.order_datetime.in_time_zone("America/Lima"), format: :short) : "",
        record.seller_name,
        helpers.number_to_currency(record.order_total.to_f / 100, unit: "S/", format: "%u %n"),
        "#{record.commission_percentage}%",
        helpers.number_to_currency(record.calculated_commission.to_f / 100, unit: "S/", format: "%u %n"),
        record.invoice_custom_id.present? ? helpers.link_to(record.invoice_custom_id, admin_invoice_path(Invoice.find_by(custom_id: record.invoice_custom_id)), target: "_blank") : "",
        record.order_id.present? ? helpers.link_to("Ver Orden", admin_order_path(record.order_id), class: "text-blue-600 hover:text-blue-800 underline") : ""
      ]
    end
  end

  def format_for_datatable(records, total_records)
    {
      draw: params[:draw].to_i,
      recordsTotal: total_records,
      recordsFiltered: total_records,
      data: records.map { |record| format_record_for_datatable(record) }
    }
  end
end
