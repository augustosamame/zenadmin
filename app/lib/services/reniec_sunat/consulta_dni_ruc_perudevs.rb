require "httparty"

module Services
  module ReniecSunat
    class ConsultaDniRucPerudevs
      include HTTParty
      base_uri "https://api.perudevs.com/api/v1"

      def self.consultar_dni(numero)
        response = get("/dni/complete?document=#{numero}&key=#{ENV["PERUDEVS_API_TOKEN"]}")
        response.parsed_response
      end

      def self.consultar_ruc(numero)
        headers = {
          "Accept" => "application-json",
        }

        response = get("/ruc?document=#{numero}&key=#{ENV["PERUDEVS_API_TOKEN"]}")
        response.parsed_response
      end
    end
  end
end
