module Services
  module Inventory
    class StockTransferGuiaService
      def initialize(stock_transfer, options = {})
        @stock_transfer = stock_transfer
        @options = options
      end

      def create_guias
        guia_data = prepare_guia_data

        # Don't generate guias for specific cases if needed
        # For example:
        # return nil if [specific_condition]

        response = Integrations::Nubefact.new.emitir_guia(guia_data.to_json)
        Rails.logger.info("Guia Response: #{response.parsed_response}")
        Rails.logger.info("Guia Response text: #{response.parsed_response["response_text"]}")

        guia = Guia.new(
          stock_transfer: @stock_transfer,
          custom_id: guia_data[:invoice_number],
          guia_series: @guia_series,
          amount: @stock_transfer.total_products,
          guia_type: "guia_remision",
          guia_sunat_sent_text: guia_data.to_json,
          guia_sunat_response: response.parsed_response,
          guia_url: response.parsed_response["response_url"]
        )

        if response.parsed_response["response_text"]
          if response.parsed_response["response_text"] == "OK"
            guia.sunat_status = "sunat_success"
            guia.status = "issued"
          else
            guia.sunat_status = "sunat_error"
            guia.status = "issued"
          end
        else
          guia.sunat_status = "application_error"
        end

        guia.save
        guia
      end

      def prepare_guia_data
        # Get the appropriate guia series
        @guia_series = determine_guia_series

        # Prepare line items
        guia_line_ids = []
        @stock_transfer.stock_transfer_lines.each do |transfer_line|
          product = transfer_line.product
          guia_line_ids << {
            "name": product.name,
            "description": product.description,
            "product_id": product.custom_id,
            "quantity": transfer_line.quantity.round(0),
            "unit_of_measure": product.unit_of_measure || "NIU", # Default to NIU if not specified
            "weight": product.weight || 1.0 # Default weight if not specified
          }
        end

        # Prepare the main data hash
        guia_data_hash = {
          "envio_codigo_traslado": determine_codigo_guia(@stock_transfer),
          "guia_tipo_doc_sent_to_efact": @guia_series.guia_type == "guia_remision" ? "remitente" : "transportista",
          "tipo_doc": "09",
          "date_invoice": @options[:date_invoice] || Time.current.strftime("%Y-%m-%d"),
          "invoice_number": @guia_series.next_invoice_number,
          "stock_transfer_custom_id": @stock_transfer.custom_id,
          "document_type": "09", # 09 is the code for Guia de Remision
          "issuer_ruc": @guia_series.invoicer.ruc,
          "issuer_razon_social": @guia_series.invoicer.razon_social,
          "issuer_address": @guia_series.invoicer.address,
          "origin_address": @stock_transfer.origin_warehouse.address,
          "destination_address": @stock_transfer.destination_warehouse.address,
          "recipient_name": @stock_transfer.destination_warehouse.name,
          "recipient_document_type": "6", # RUC
          "recipient_document_number": @guia_series.invoicer.ruc, # Using the same RUC as issuer for internal transfers
          "transfer_reason": "01", # 01 is the code for Sale
          "transport_mode": "01", # 01 is the code for Public transport
          "efact_client_token": @guia_series.invoicer.einvoice_api_key,
          "guia_line_ids": guia_line_ids,
          "comments": @options[:comments] || "Transferencia de stock #{@stock_transfer.custom_id}"
        }

        guia_data_hash
      end

      def determine_guia_series
        # Logic to determine the appropriate guia series
        # This is a placeholder - you'll need to implement the actual logic based on your requirements
        guia_series = GuiaSeries.where(active: true, guia_type: "guia_remision").first

        if guia_series.blank?
          raise "No active guia series found for guia_remision type"
        end

        guia_series
      end
    end
  end
end
