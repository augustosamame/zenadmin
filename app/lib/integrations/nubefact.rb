module Integrations
  class Nubefact
    # this service consumes the efact_sunat webservice to emit and void invoices via Nubefact

    include ActionView::Helpers::NumberHelper
    include HTTParty
    base_uri Rails.env.production? ? "https://efact.devtechperu.net" : "https://efact.devtechperu.net"

    def initialize
    end

    def emitir_comprobante(invoice_data)
      headers = {
        "Content-Type" => "application/json",
        "authorization" => "#{JSON.parse(invoice_data)['efact_client_token']}"
      }
      self.class.post("/invoice", body: invoice_data, headers: headers)
    end

    def anular_comprobante(invoice_data)
      headers = {
        "Content-Type" => "application/json",
        "authorization" => "#{JSON.parse(invoice_data)['efact_client_token']}"
      }
      self.class.post("/invoice", body: invoice_data, headers: headers)
    end

    def emitir_guia(guia_data)
      headers = {
        "Content-Type" => "application/json",
        "authorization" => "#{JSON.parse(guia_data)['efact_client_token']}"
      }
      self.class.post("/invoice", body: guia_data, headers: headers)
    end
  end
end
