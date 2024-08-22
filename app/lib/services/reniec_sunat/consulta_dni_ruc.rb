# convert this command curl -H 'Accept: application/json' -H "Authorization: Bearer $TOKEN" https://api.apis.net.pe/v2/reniec/dni?numero=46027897 into httparty calls

require "httparty"

module Services
  module ReniecSunat
    class ConsultaDniRuc
      include HTTParty
      base_uri "https://api.apis.net.pe/v2"

      def self.consultar_dni(numero)
        headers = {
          "Accept" => "application-json",
          "Authorization" => "Bearer #{ENV["APIS_NET_PE_TOKEN"]}"
        }

        response = get("/reniec/dni?numero=#{numero}", headers: headers)
        response.parsed_response
      end

      def self.consultar_ruc(numero)
        headers = {
          "Accept" => "application-json",
          "Authorization" => "Bearer #{ENV["APIS_NET_PE_TOKEN"]}"
        }

        response = get("/sunat/ruc/full?numero=#{numero}", headers: headers)
        response.parsed_response
      end
    end
  end
end
