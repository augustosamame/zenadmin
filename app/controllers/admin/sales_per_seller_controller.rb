class Admin::SalesPerSellerController < Admin::AdminController
  # GET /admin/sales_per_seller
  # Regular view with detailed sales
  def index
    # Debug all parameters
    Rails.logger.debug "INDEX - ALL PARAMS: #{params.inspect}"
    Rails.logger.debug "INDEX - FILTER PARAMS: #{params[:filter].inspect}"

    # Check if this is a "Quitar Filtros" request (no filter params)
    reset_filters = params[:filter].nil? && params[:filterParams].nil? && !params[:filter].is_a?(String)

    if reset_filters
      # Clear all session values
      session.delete(:sales_per_seller_from_date)
      session.delete(:sales_per_seller_to_date)
    end

    # Set consolidated_by_seller to false for this view
    @consolidated_by_seller = false

    # Extract and process filter parameters
    extract_filter_params

    # Set datatable options with filter parameters included in the AJAX URL
    ajax_url = admin_sales_per_seller_index_path(format: :json, from_date: @from_date, to_date: @to_date)
    @datatable_options = "resource_name:'sales_per_seller';sort_1_desc;server_side:true;date_filter:true;ajax_url:'#{ajax_url}'"

    respond_to do |format|
      format.html
      format.json do
        # Get location_id from params or current_location
        location_id = params[:location_id].presence || @current_location&.id

        # Get data for datatable
        data = datatable_json(location_id)

        render json: data
      end
    end
  end

  # GET /admin/sales_per_seller/consolidated
  # Consolidated view grouped by seller
  def consolidated
    # Debug all parameters
    Rails.logger.debug "CONSOLIDATED - ALL PARAMS: #{params.inspect}"
    Rails.logger.debug "CONSOLIDATED - FILTER PARAMS: #{params[:filter].inspect}"

    # Check if this is a "Quitar Filtros" request (no filter params)
    reset_filters = params[:filter].nil? && params[:filterParams].nil? && !params[:filter].is_a?(String)

    if reset_filters
      # Clear all session values
      session.delete(:sales_per_seller_from_date)
      session.delete(:sales_per_seller_to_date)
    end

    # Set consolidated_by_seller to true for this view
    @consolidated_by_seller = true

    # Extract and process filter parameters
    extract_filter_params

    # Set datatable options with filter parameters included in the AJAX URL
    ajax_url = consolidated_admin_sales_per_seller_index_path(format: :json, from_date: @from_date, to_date: @to_date)
    @datatable_options = "resource_name:'consolidated_sales_per_seller';sort_1_desc;server_side:true;date_filter:true;ajax_url:'#{ajax_url}'"

    respond_to do |format|
      format.html
      format.json do
        # Get location_id from params or current_location
        location_id = params[:location_id].presence || @current_location&.id

        # Get data for datatable
        data = datatable_json(location_id)

        render json: data
      end
    end
  end

  private

  # Extract filter parameters - start with an empty hash
  def extract_filter_params
    filter_params = {}

    # Log all parameters for debugging
    Rails.logger.debug "EXTRACT FILTER PARAMS - ALL PARAMS: #{params.inspect}"

    # Check for parameters at the root level first (from AJAX)
    if params[:from_date].present? || params[:to_date].present?
      filter_params[:from_date] = params[:from_date].to_s if params[:from_date].present?
      filter_params[:to_date] = params[:to_date].to_s if params[:to_date].present?
      Rails.logger.debug "FILTER FROM ROOT LEVEL: #{filter_params.inspect}"
    # Then check for filter hash from form submission
    elsif params[:filter].present?
      if params[:filter].is_a?(ActionController::Parameters)
        # Use permit! to allow all parameters
        filter_params = params[:filter].permit!.to_h
        Rails.logger.debug "FILTER FROM FORM: #{filter_params.inspect}"
      elsif params[:filter].is_a?(String)
        # Check for filter as JSON string (from location dropdown)
        begin
          filter_params = JSON.parse(params[:filter])
          Rails.logger.debug "FILTER FROM STRING: #{filter_params.inspect}"
        rescue JSON::ParserError => e
          Rails.logger.error "Error parsing filter string: #{e.message}"
        end
      else
        # Handle any other type safely
        Rails.logger.warn "Unexpected filter parameter type: #{params[:filter].class}"
      end
    # Finally check for filterParams object (legacy support)
    elsif params[:filterParams].present?
      if params[:filterParams].is_a?(ActionController::Parameters)
        # Use permit! for filterParams
        filter_params = params[:filterParams].permit!.to_h
      elsif params[:filterParams].is_a?(Hash)
        filter_params = params[:filterParams]
      elsif params[:filterParams].is_a?(String)
        begin
          filter_params = JSON.parse(params[:filterParams])
        rescue JSON::ParserError => e
          Rails.logger.error "Error parsing filterParams string: #{e.message}"
        end
      else
        Rails.logger.warn "Unexpected filterParams type: #{params[:filterParams].class}"
      end
      Rails.logger.debug "FILTER FROM AJAX: #{filter_params.inspect}"
    end

    Rails.logger.debug "FINAL FILTER PARAMS: #{filter_params.inspect}"

    # Extract from_date
    if filter_params[:from_date].present?
      @from_date = filter_params[:from_date]
      session[:sales_per_seller_from_date] = @from_date
    elsif session[:sales_per_seller_from_date].present?
      @from_date = session[:sales_per_seller_from_date]
    else
      @from_date = Date.today.beginning_of_month.strftime("%Y-%m-%d")
      session[:sales_per_seller_from_date] = @from_date
    end

    # Extract to_date
    if filter_params[:to_date].present?
      @to_date = filter_params[:to_date]
      session[:sales_per_seller_to_date] = @to_date
    elsif session[:sales_per_seller_to_date].present?
      @to_date = session[:sales_per_seller_to_date]
    else
      @to_date = Date.today.strftime("%Y-%m-%d")
      session[:sales_per_seller_to_date] = @to_date
    end

    # Convert dates to Date objects
    @from_date = Date.parse(@from_date) if @from_date.is_a?(String)
    @to_date = Date.parse(@to_date) if @to_date.is_a?(String)

    # Create date range for filtering
    @date_range = @from_date.beginning_of_day..@to_date.end_of_day

    Rails.logger.debug "DATE RANGE: #{@date_range}"
  end

  # Generate JSON data for datatables
  def datatable_json(location_id)
    Rails.logger.debug "DATATABLE JSON - PARAMS: #{params.inspect}"
    Rails.logger.debug "DATATABLE JSON - DATE RANGE: #{@date_range}"
    Rails.logger.debug "DATATABLE JSON - CONSOLIDATED: #{@consolidated_by_seller}"

    # Re-extract filter parameters for AJAX requests
    # This ensures we get the latest parameters from the request
    extract_filter_params

    # Convert date range to UTC for database queries
    from_date = @date_range.begin.in_time_zone("America/Lima").beginning_of_day.utc
    to_date = @date_range.end.in_time_zone("America/Lima").end_of_day.utc

    # Build base query with all necessary joins
    base_query = Commission.joins(:user)
                          .joins("INNER JOIN users sellers ON commissions.user_id = sellers.id")
                          .joins("INNER JOIN orders ON commissions.order_id = orders.id")
                          .joins("INNER JOIN users customers ON orders.user_id = customers.id")
                          .joins("INNER JOIN locations ON orders.location_id = locations.id")
                          .joins("LEFT JOIN (SELECT DISTINCT ON (payable_id, payable_type) * FROM payments WHERE payable_type = 'Order' ORDER BY payable_id, payable_type, created_at DESC) AS payments ON payments.payable_id = orders.id AND payments.payable_type = 'Order'")
                          .joins("LEFT JOIN payment_methods ON payments.payment_method_id = payment_methods.id")
                          .joins("LEFT JOIN invoices ON orders.id = invoices.order_id")

    # Apply date range filter
    base_query = base_query.where("orders.order_date BETWEEN ? AND ?", from_date, to_date)

    # Apply location filter if present
    base_query = base_query.where("orders.location_id = ?", location_id) if location_id.present?

    # Determine if we should consolidate by seller
    Rails.logger.debug "JSON request - column index: #{params[:order].try(:[], '0').try(:[], 'column')}"

    if @consolidated_by_seller
      # Consolidated view - group by seller
      Rails.logger.debug "USING CONSOLIDATED QUERY"

      # Select fields for consolidated view
      select_fields = [
        "sellers.id as user_id",
        "CONCAT(sellers.first_name, ' ', sellers.last_name) as seller_name",
        "COUNT(DISTINCT orders.id) as order_count",
        "SUM(orders.total_price_cents * commissions.percentage / 100) as total_commission"
      ]
      
      # Add location name if a specific location is selected
      if location_id.present? && location_id != 'all'
        select_fields << "MAX(locations.name) as location_name"
        # Add location_id to group by to ensure we get the right name
        group_fields = "sellers.id, sellers.first_name, sellers.last_name"
      else
        # For 'all' locations, we don't need to include location in the query
        group_fields = "sellers.id, sellers.first_name, sellers.last_name"
      end

      # Group by seller to ensure uniqueness
      subquery = base_query.select(select_fields)
                         .group(group_fields)
                         .order("sellers.id ASC")
      
      # Then wrap it in an outer query that can be sorted however we want
      if params.dig(:order, "0", :column).present?
        # Get the sort column and direction
        sort_column = params.dig(:order, "0", :column).to_i
        sort_dir = params.dig(:order, "0", :dir) || "asc"
        
        # Map the column index to the actual column name in the result set
        sort_field = case sort_column
          when 0 # Location - not really sortable in consolidated view
            "user_id"
          when 3 # Seller name
            "seller_name"
          when 4 # Total commission
            "total_commission"
          when 5 # Order count
            "order_count"
          else
            "user_id"
        end
        
        # Apply the sort to the outer query
        base_query = Commission.from("(#{subquery.to_sql}) as commissions")
                             .order("#{sort_field} #{sort_dir}")
      else
        # Default order
        base_query = Commission.from("(#{subquery.to_sql}) as commissions")
                             .order("user_id ASC")
      end

      # Format records for datatable
      records = base_query.map do |record|
        format_consolidated_record_for_datatable(record)
      end
    else
      # Detailed view - show all commissions
      Rails.logger.debug "USING DETAILED QUERY"

      # Select fields for detailed view
      select_fields = [
        "orders.id as order_id",
        "orders.custom_id",
        "orders.order_date as order_datetime",
        "locations.name as location_name",
        "sellers.id as user_id",
        "CONCAT(sellers.first_name, ' ', sellers.last_name) as seller_name",
        "customers.id as customer_user_id",
        "CONCAT(customers.first_name, ' ', customers.last_name) as customer_name",
        "orders.total_price_cents as order_total",
        "commissions.percentage as commission_percentage",
        "commissions.amount_cents as commission_amount",
        "(orders.total_price_cents * commissions.percentage / 100) as calculated_commission",
        "payment_methods.description as payment_method",
        "payments.amount_cents as payment_total",
        "payments.processor_transacion_id as payment_tx",
        "invoices.custom_id as invoice_custom_id",
        "invoices.sunat_status as invoice_status",
        "invoices.invoice_url as invoice_url"
      ]

      # For sorting with uniqueness, we need a different approach
      # First, get a subquery with DISTINCT ON to ensure uniqueness
      subquery = base_query.select("DISTINCT ON (sellers.id, orders.id) " + select_fields.join(", "))
                         .order("sellers.id, orders.id")
      
      # Then wrap it in an outer query that can be sorted however we want
      if params.dig(:order, "0", :column).present?
        # Get the SQL for the selected column
        sort_column = params.dig(:order, "0", :column).to_i
        sort_dir = params.dig(:order, "0", :dir) || "asc"
        
        # Map the column index to the actual column name in the result set
        sort_field = case sort_column
          when 0 # Location
            "location_name"
          when 1 # Order ID
            "custom_id"
          when 2 # Date
            "order_datetime"
          when 3 # Seller
            "seller_name"
          when 4 # Order Total
            "order_total"
          when 5 # Commission Percentage
            "commission_percentage"
          when 6 # Commission Amount
            "calculated_commission"
          else
            "order_id"
        end
        
        # Apply the sort to the outer query
        base_query = Commission.from("(#{subquery.to_sql}) as commissions")
                             .order("#{sort_field} #{sort_dir}")
      else
        # Default order
        base_query = Commission.from("(#{subquery.to_sql}) as commissions")
                             .order("order_id ASC")
      end

      # Format records for datatable
      records = base_query.map do |record|
        format_record_for_datatable(record)
      end
    end

    # Return datatable response
    {
      draw: params[:draw].to_i,
      recordsTotal: records.size,
      recordsFiltered: records.size,
      data: records
    }
  end

  def order_column_sql(column = nil, direction = nil)
    column_index = (column || order_column).to_i
    direction = direction || order_direction || "desc"

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
      "orders.total_price_cents #{direction}"
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

  def format_consolidated_record_for_datatable(record)
    # For location name, use the one from the query if available
    location_display = if params[:location_id].present? && params[:location_id] != 'all'
                        # If we have a specific location selected, use the location name from the query
                        record.location_name
                      else
                        # If 'all' locations are selected, show "Todas las tiendas"
                        "Todas las tiendas"
                      end
                    
    [
      location_display,
      "", # No order ID for consolidated view
      "", # No date for consolidated view
      record.seller_name,
      helpers.number_to_currency(record.total_commission.to_f / 100, unit: "S/", format: "%u %n"),
      record.order_count.to_s, # Number of orders instead of commission percentage
      "", # No commission column
      "", # No invoice for consolidated view
      ""  # No actions for consolidated view
    ]
  end

  def format_record_for_datatable(record)
    [
      record.location_name,
      record.custom_id,
      record.order_datetime ? I18n.l(record.order_datetime.in_time_zone("America/Lima"), format: :short) : "",
      record.seller_name,
      helpers.number_to_currency(record.order_total.to_f / 100, unit: "S/", format: "%u %n"),
      "#{record.commission_percentage}%",
      helpers.number_to_currency(record.calculated_commission.to_f / 100, unit: "S/", format: "%u %n"),
      record.invoice_custom_id.present? ? helpers.link_to(record.invoice_custom_id, record.invoice_url, target: "_blank") : "",
      record.order_id.present? ? helpers.link_to("Ver Orden", admin_order_path(record.order_id), class: "text-blue-600 hover:text-blue-800 underline") : ""
    ]
  end
end
