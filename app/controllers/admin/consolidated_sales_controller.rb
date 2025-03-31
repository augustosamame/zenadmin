class Admin::ConsolidatedSalesController < Admin::AdminController
  def index
    # Extract filter parameters
    filter_params = {}
    
    if params[:filter].is_a?(String)
      # Handle the case where filter is a string (from location dropdown)
      Rails.logger.debug "Filter is a string: #{params[:filter]}"
      # Try to parse the string format "from_date VALUE to_date VALUE consolidated_by_payment_method VALUE"
      filter_string = params[:filter]
      
      # Extract from_date
      from_date_match = filter_string.match(/from_date\s+(\S+)/)
      filter_params[:from_date] = from_date_match[1] if from_date_match
      
      # Extract to_date
      to_date_match = filter_string.match(/to_date\s+(\S+)/)
      filter_params[:to_date] = to_date_match[1] if to_date_match
      
      # Extract consolidated_by_payment_method
      consolidated_match = filter_string.match(/consolidated_by_payment_method\s+(\S+)/)
      filter_params[:consolidated_by_payment_method] = consolidated_match[1] if consolidated_match
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
      session[:consolidated_sales_from_date] = @from_date
    elsif session[:consolidated_sales_from_date].present?
      @from_date = session[:consolidated_sales_from_date]
    else
      @from_date = Date.current.beginning_of_month
      session[:consolidated_sales_from_date] = @from_date
    end

    if filter_params[:to_date].present?
      @to_date = filter_params[:to_date].to_date
      session[:consolidated_sales_to_date] = @to_date
    elsif session[:consolidated_sales_to_date].present?
      @to_date = session[:consolidated_sales_to_date]
    else
      @to_date = Date.current
      session[:consolidated_sales_to_date] = @to_date
    end

    # Handle consolidated_by_payment_method filter
    if filter_params.key?(:consolidated_by_payment_method)
      consolidated_value = filter_params[:consolidated_by_payment_method]
      @consolidated_by_payment_method = consolidated_value.to_s == "true" || consolidated_value.to_s == "1"
      session[:consolidated_sales_by_payment_method] = @consolidated_by_payment_method
    elsif session[:consolidated_sales_by_payment_method].present?
      @consolidated_by_payment_method = session[:consolidated_sales_by_payment_method]
    else
      @consolidated_by_payment_method = false
      session[:consolidated_sales_by_payment_method] = @consolidated_by_payment_method
    end

    @date_range = @from_date..@to_date
    
    Rails.logger.debug "SESSION VALUES: from_date=#{session[:consolidated_sales_from_date]}, to_date=#{session[:consolidated_sales_to_date]}, consolidated_by_payment_method=#{session[:consolidated_sales_by_payment_method]}"
    Rails.logger.debug "INSTANCE VALUES: from_date=#{@from_date}, to_date=#{@to_date}, consolidated_by_payment_method=#{@consolidated_by_payment_method}"

    @orders = if @consolidated_by_payment_method
      Order.consolidated_sales_by_payment_method(
        location: @current_location,
        date_range: @date_range,
        order_column: order_column,
        order_direction: order_direction,
        search_term: params.dig("search", "value") || nil
      )
    else
      Order.consolidated_sales(
        location: @current_location,
        date_range: @date_range,
        order_column: order_column,
        order_direction: order_direction,
        search_term: params.dig("search", "value") || nil
      )
    end

    respond_to do |format|
      format.html do
        @datatable_options = "server_side:true;resource_name:'ConsolidatedSales';create_button:false;sort_1_desc:true;order_1_1:true;date_filter:true;row_group:'custom_id'"
      end
      format.json do
        # For consolidated view, we need to count differently
        if @consolidated_by_payment_method
          # For consolidated view, we need the actual count of grouped records
          total_records = @orders.length
        else
          # For regular view, we can use the standard count
          total_records = @orders.except(:select).count
        end
        
        start = params[:start].to_i
        length = params[:length].to_i
        
        # Apply pagination
        if length > 0
          if @consolidated_by_payment_method
            # For consolidated view with few records, we need to handle pagination manually
            @orders = @orders.to_a[start, length] || []
          else
            # For regular view, we can use ActiveRecord pagination
            @orders = @orders.limit(length).offset(start)
          end
        end

        render json: format_for_datatable(@orders, total_records)
      end
    end
  end

  private

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

  def format_for_datatable(records, total_records)
    {
      draw: params[:draw].to_i,
      recordsTotal: total_records,
      recordsFiltered: total_records,
      data: records.map do |record|
        [
          record.location_name,
          record.custom_id,
          record.order_datetime ? I18n.l(record.order_datetime.in_time_zone("America/Lima"), format: :short) : "",
          record.customer_name,
          helpers.number_to_currency(record.order_total.to_f / 100, unit: "S/", format: "%u %n"),
          record.payment_method,
          helpers.number_to_currency(record.payment_total.to_f / 100, unit: "S/", format: "%u %n"),
          record.payment_tx,
          record.invoice_custom_id.present? ? helpers.link_to(record.invoice_custom_id, record.invoice_url, target: "_blank") : "",
          record.invoice_status.present? ? Invoice.sunat_statuses.key(record.invoice_status.to_i)&.humanize : "",
          record.missing_commission ? helpers.content_tag(:span, "Sin comisión", class: "inline-flex items-center rounded-md bg-red-50 px-2 py-1 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/10") : "",
          record.id.present? ? helpers.link_to("Ver Detalles", admin_order_path(record.id), class: "text-blue-600 hover:text-blue-800 underline") : ""
        ]
      end
    }
  end
end
