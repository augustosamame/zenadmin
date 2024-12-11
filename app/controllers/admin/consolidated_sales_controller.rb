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
        @datatable_options = "server_side:true;resource_name:'ConsolidatedSales';create_button:false;sort_1_desc:true;order_1_1:true;date_filter:true"
      end
      format.json do
        render json: format_for_datatable(@orders)
      end
      format.csv { send_data to_csv(@orders), filename: "ventas_consolidadas_#{Date.current}.csv" }
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

  def format_for_datatable(records)
    {
      draw: params[:draw].to_i,
      recordsTotal: records.length,
      recordsFiltered: records.length,
      data: records.map do |record|
        [
          record.location_name,
          record.custom_id,
          I18n.l(record.order_datetime.to_datetime, format: :short),
          record.customer_name,
          helpers.number_to_currency(record.order_total.to_f / 100, unit: "S/", format: "%u %n"),
          record.payment_method,
          helpers.number_to_currency(record.payment_total.to_f / 100, unit: "S/", format: "%u %n"),
          record.payment_tx,
          record.invoice_custom_id,
          helpers.link_to("Ver Detalles", admin_order_path(record.id), class: "btn btn-link")
        ]
      end
    }
  end

  def to_csv(orders)
    headers = %w[Tienda Orden Fecha Cliente Total Método\ Pago Total\ Pago Tx\ # Comprobante]

    CSV.generate(headers: true) do |csv|
      csv << headers

      orders.each do |order|
        csv << [
          order.location_name,
          order.order_custom_id,
          order.order_datetime&.strftime("%d/%m/%Y %H:%M"),
          order.customer_name,
          order.order_total&.to_f&./(100),
          order.payment_method,
          order.payment_total&.to_f&.fdiv(100),
          order.payment_tx,
          order.invoice_custom_id
        ]
      end
    end
  end
end
