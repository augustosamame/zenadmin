class Admin::ConsolidatedSalesController < Admin::AdminController
  def index
    # Extract filter parameters
    filter_params = {}

    if params[:filter].is_a?(String)
      # Handle the case where filter is a string (from location dropdown)
      Rails.logger.debug "Filter is a string: #{params[:filter]}"
      # Try to parse the string format "from_date VALUE to_date VALUE consolidated_by_payment_method VALUE total_general VALUE"
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

      # Extract total_general
      total_general_match = filter_string.match(/total_general\s+(\S+)/)
      filter_params[:total_general] = total_general_match[1] if total_general_match
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

    # Handle total_general filter
    if filter_params.key?(:total_general)
      total_general_value = filter_params[:total_general]
      @total_general = total_general_value.to_s == "true" || total_general_value.to_s == "1"
      session[:consolidated_sales_total_general] = @total_general
    elsif session[:consolidated_sales_total_general].present?
      @total_general = session[:consolidated_sales_total_general]
    else
      @total_general = false
      session[:consolidated_sales_total_general] = @total_general
    end

    @date_range = @from_date..@to_date

    Rails.logger.debug "SESSION VALUES: from_date=#{session[:consolidated_sales_from_date]}, to_date=#{session[:consolidated_sales_to_date]}, consolidated_by_payment_method=#{session[:consolidated_sales_by_payment_method]}, total_general=#{session[:consolidated_sales_total_general]}"
    Rails.logger.debug "INSTANCE VALUES: from_date=#{@from_date}, to_date=#{@to_date}, consolidated_by_payment_method=#{@consolidated_by_payment_method}, total_general=#{@total_general}"

    # Determine which view to show based on checkboxes
    # If both are checked, prioritize Total General
    if @total_general
      if @current_location.nil?
        # "Todas" is selected - get all locations data
        @orders = Order.consolidated_sales_by_location(
          date_range: @date_range,
          order_column: order_column,
          order_direction: order_direction,
          search_term: params.dig("search", "value") || nil
        )
      else
        # Specific location is selected - get data for that location
        @orders = Order.consolidated_sales_by_location(
          location_id: @current_location.id,
          date_range: @date_range,
          order_column: order_column,
          order_direction: order_direction,
          search_term: params.dig("search", "value") || nil
        )
      end
    elsif @consolidated_by_payment_method
      @orders = Order.consolidated_sales_by_payment_method(
        location: @current_location,
        date_range: @date_range,
        order_column: order_column,
        order_direction: order_direction,
        search_term: params.dig("search", "value") || nil
      )
    else
      @orders = Order.consolidated_sales(
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
        if @consolidated_by_payment_method || @total_general
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
          if @consolidated_by_payment_method || @total_general
            # For consolidated view with few records, we need to handle pagination manually
            @orders = @orders.to_a[start, length] || []
          else
            # For regular view, we can use ActiveRecord pagination
            @orders = @orders.limit(length).offset(start)
          end
        end

        # Prepare data for datatable
        orders_data = @orders.map do |record|
          format_record_for_datatable(record)
        end

        # Handle "Total General" checkbox
        if @total_general
          # If we're already showing totals by location, we don't need to add more rows
          # Just add a grand total row if we're showing multiple locations
          if @current_location.nil? && orders_data.any?
            # Calculate grand total across all locations
            grand_total_payment = @orders.sum { |r| r.payment_total.to_f }
            # Count the number of records instead of using order_count
            grand_total_count = @orders.length

            # Add grand total row
            grand_total_row = [
              "TODAS LAS TIENDAS (Total: #{grand_total_count} registros)",
              "", # No order ID for summary
              "", # No date for summary
              "TOTAL GENERAL",
              "", # No order total for consolidated view
              "", # No payment method for summary
              helpers.number_to_currency(grand_total_payment / 100, unit: "S/", format: "%u %n"),
              "", # No payment tx for summary
              "", # No invoice for summary
              "", # No invoice status for summary
              "", # No commission status for summary
              ""  # No actions for summary
            ]

            # Add to the end of the data array so it appears at the bottom
            orders_data << grand_total_row
          end
        # Handle "Consolidado por Medio de Pago" checkbox
        elsif @consolidated_by_payment_method && orders_data.any?
          # Calculate total across all payment methods
          total_payment_amount = @orders.sum { |r| r.payment_total.to_f }
          # Count the number of records instead of using order_count
          total_count = @orders.length

          # Get location name for the total row
          location_name = @current_location ? @current_location.name : "Todas las Tiendas"

          # Add a total row for all payment methods
          total_row = [
            location_name,
            "", # No order ID for summary
            "", # No date for summary
            "TOTAL TODOS LOS MEDIOS DE PAGO (#{total_count} medios)",
            "", # No order total for consolidated view
            "", # No payment method for summary
            helpers.number_to_currency(total_payment_amount / 100, unit: "S/", format: "%u %n"),
            "", # No payment tx for summary
            "", # No invoice for summary
            "", # No invoice status for summary
            "", # No commission status for summary
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
    # For consolidated views, don't show order total
    if @consolidated_by_payment_method || @total_general
      [
        record.location_name,
        record.custom_id,
        record.order_datetime ? I18n.l(record.order_datetime.in_time_zone("America/Lima"), format: :short) : "",
        record.customer_name,
        "", # No order total for consolidated view
        record.payment_method,
        helpers.number_to_currency(record.payment_total.to_f / 100, unit: "S/", format: "%u %n"),
        record.payment_tx,
        record.invoice_custom_id.present? ? helpers.link_to(record.invoice_custom_id, record.invoice_url, target: "_blank") : "",
        record.invoice_status.present? ? Invoice.sunat_statuses.key(record.invoice_status.to_i)&.humanize : "",
        record.missing_commission ? helpers.content_tag(:span, "Sin comisión", class: "inline-flex items-center rounded-md bg-red-50 px-2 py-1 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/10") : "",
        record.id.present? ? helpers.link_to("Ver Detalles", admin_order_path(record.id), class: "text-blue-600 hover:text-blue-800 underline") : ""
      ]
    else
      # For regular view, show all columns
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
