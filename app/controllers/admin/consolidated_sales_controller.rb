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
      order_direction: order_direction
    )

    respond_to do |format|
      format.html do
        @datatable_options = "server_side:true;resource_name:'ConsolidatedSales';create_button:false;sort_1_desc:true;order_1_1:true"
      end
      format.json { render json: format_for_datatable(@orders) }
      format.csv { send_data to_csv(@orders), filename: "ventas_consolidadas_#{Date.current}.csv" }
    end
  end

  private

  def order_column
    columns = %w[location_name order_custom_id order_datetime customer_name order_total payment_method payment_total payment_tx invoice_custom_id actions]
    columns[params.dig(:order, "0", :column).to_i] || "order_custom_id"
  end

  def order_direction
    params.dig(:order, "0", :dir) == "desc" ? "desc" : "asc"
  end

  def format_for_datatable(orders)
    {
      draw: params[:draw].to_i,
      recordsTotal: orders.length,
      recordsFiltered: orders.length,
      data: orders.map { |order| format_order(order) }
    }
  end

  def format_order(order)
    if order.is_a?(OpenStruct) && order.invoice_custom_id&.start_with?("⚠️")
      # This is an error record for a missing invoice
      [
        nil,  # location_name
        nil,  # order_custom_id
        nil,  # order_datetime
        nil,  # customer_name
        nil,  # order_total
        nil,  # payment_method
        nil,  # payment_total
        nil,  # payment_tx
        order.invoice_custom_id,  # Show the error message
        nil   # No actions for error records
      ]
    else
      # Normal record formatting
      [
        order.location_name,
        order.order_custom_id,
        order.order_datetime&.strftime("%d/%m/%Y %H:%M"),
        order.customer_name,
        helpers.format_currency(Money.new(order.order_total || 0, "PEN")),
        order.payment_method,
        order.payment_total ? helpers.format_currency(Money.new(order.payment_total, "PEN")) : "",
        order.payment_tx,
        order.invoice_custom_id,
        helpers.link_to("Ver Detalles", admin_order_path(order.id), class: "btn btn-link")
      ]
    end
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
