module Integrations
  class Nubefact
    # this service consumes the efact_sunat webservice to emit and void invoices via Nubefact

    include ActionView::Helpers::NumberHelper
    include HTTParty
    base_uri Rails.env.production? ? "https://efactsunat.devtechperu.com" : "http://localhost:3002"

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
  end
end
