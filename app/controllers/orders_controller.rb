class OrdersController < ApplicationController
  def invoice
    @order = Order.find(params[:id])
    @invoice_result = @order.universal_invoice_show

    case @invoice_result[:status]
    when :ready
      redirect_to @invoice_result[:url], allow_other_host: true
    when :pending
      render json: { message: @invoice_result[:message] }, status: :ok
    else
      render plain: "Ocurrió un error al generar el comprobante. Por favor, inténtelo de nuevo más tarde.", status: :internal_server_error
    end
  end

  def invoice_xml
    @order = Order.find(params[:id])
    redirect_to @order.universal_xml_link, allow_other_host: true
  end
end
