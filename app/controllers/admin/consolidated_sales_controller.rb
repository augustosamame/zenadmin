class Admin::ConsolidatedSalesController < Admin::AdminController
  def index
    filter_params = params.fetch(:filter, {})
    filter_params = {} unless filter_params.is_a?(ActionController::Parameters)

    @from_date = filter_params[:from_date].presence&.to_date || Date.current.beginning_of_month
    @to_date = filter_params[:to_date].presence&.to_date || Date.current
    @date_range = @from_date..@to_date

    @orders = Order.consolidated_sales(
      location: @current_location,
      date_range: @date_range,
      order_column: order_column,
      order_direction: order_direction,
      search_term: params.dig("search", "value") || nil
    )

    respond_to do |format|
      format.html do
        @datatable_options = "server_side:true;resource_name:'ConsolidatedSales';create_button:false;sort_1_desc:true;order_1_1:true;date_filter:true;row_group:'custom_id'"
      end
      format.json do
        total_records = @orders.except(:select).count
        start = params[:start].to_i
        length = params[:length].to_i
        @orders = @orders.limit(length).offset(start) if length > 0

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
          I18n.l(record.order_datetime.in_time_zone("America/Lima"), format: :short),
          record.customer_name,
          helpers.number_to_currency(record.order_total.to_f / 100, unit: "S/", format: "%u %n"),
          record.payment_method,
          helpers.number_to_currency(record.payment_total.to_f / 100, unit: "S/", format: "%u %n"),
          record.payment_tx,
          record.invoice_custom_id.present? ? helpers.link_to(record.invoice_custom_id, record.invoice_url, target: "_blank") : "",
          record.invoice_status.present? ? Invoice.sunat_statuses.key(record.invoice_status.to_i)&.humanize : "",
          record.missing_commission ? helpers.content_tag(:span, "Sin comisión", class: "inline-flex items-center rounded-md bg-red-50 px-2 py-1 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/10") : "",
          helpers.link_to("Ver Detalles", admin_order_path(record.id), class: "text-blue-600 hover:text-blue-800 underline")
        ]
      end
    }
  end
end
