module Integrations
  class Nubefact
    #this service consumes the efact_sunat webservice to emit and void invoices via Nubefact

    include ActionView::Helpers::NumberHelper
    include HTTParty
    #base_uri "https://efactsunat.devtechperu.com"
    base_uri "http://localhost:3002"

    def initialize
      @headers = {
        "Content-Type" => "application/json",
        "authorization" => "#{ENV['FACTURADOR_DEVTECH_TOKEN']}"
      }
    end

    def emitir_comprobante(invoice_data)
      self.class.post("/invoice", body: invoice_data, headers: @headers)
    end

  end
end