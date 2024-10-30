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
    xml_url = @order.universal_xml_link

    # Validate the URL is from your trusted domain(s)
    if trusted_invoice_url?(xml_url)
      # brakeman:ignore:redirect
      redirect_to xml_url, allow_other_host: true
    else
      render plain: "Invalid invoice URL", status: :bad_request
    end
  end

  private

  def trusted_invoice_url?(url)
    return false if url.blank?

    # Add your trusted domains here
    trusted_domains = [
      "www.nubefact.com",
      "nubefact.com"
    ]

    begin
      uri = URI.parse(url)
      trusted_domains.any? { |domain| uri.host == domain }
    rescue URI::InvalidURIError
      false
    end
  end
end
