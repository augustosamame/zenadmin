module Services
  module Inventory
    class StockTransferGuiaService
      def initialize(object_origin, object_id, options = {})
        case object_origin
        when "stock_transfer"
          @stock_transfer = StockTransfer.find(object_id)
        when "venta"
          @order = Order.find(object_id)
        when "compra"
          # @purchase = Purchase.find(object_id)
        when "servicio_transporte"
          # @transport = TransportOrder.find(object_id)
        end
        @options = options
        @object_origin = object_origin
        @object_id = object_id
      end

      def create_guia
        case @object_origin
        when "stock_transfer"
          result = create_guia_from_stock_transfer
        when "venta"
          result = create_guia_from_order
        when "compra"
          # @purchase = Purchase.find(@object_id)
        when "servicio_transporte"
          # @transport = TransportOrder.find(@object_id)
        end
      end

      def create_guia_from_stock_transfer
        guia_series = determine_guia_series_for_stock_transfer

        # Prepare line items
        guia_lines = []
        @stock_transfer.stock_transfer_lines.each do |transfer_line|
          product = transfer_line.product
          guia_lines << {
            "name": product.name,
            "description": product.description,
            "product_id": product.custom_id,
            "quantity": transfer_line.quantity,
            "product_uom": product.unit_of_measure || "NIU", # Default to NIU if not specified
            "weight": product.weight || 1.0 # Default weight if not specified
          }
        end

        # Prepare the main data hash
        guia_data = {
          "guia_de_remision": true,
          "serie": guia_series.prefix,
          "envio_codigo_traslado": "04",
          "guia_tipo_doc_sent_to_efact": guia_series.guia_type == "guia_remision" ? "remitente" : "transportista",
          "tipo_doc": "09",
          "date_guia": @stock_transfer.date_guia&.strftime("%d-%m-%Y") || Time.current.strftime("%d-%m-%Y"),
          "datetime_guia": @stock_transfer.date_guia&.strftime("%d-%m-%Y %H:%M:%S") || Time.current.strftime("%d-%m-%Y %H:%M:%S"),
          "correlativo": guia_series.next_invoice_number.split("-").last,
          "stock_transfer_custom_id": @stock_transfer.custom_id,
          "document_type": "09", # 09 is the code for Guia de Remision
          "destinatario_tipo_doc": "6", # RUC
          "destinatario_ruc": guia_series.invoicer.ruc, # porque es transferencia interna
          "destinatario_razon_social": guia_series.invoicer.razon_social, # porque es transferencia interna
          "destinatario_direccion": guia_series.invoicer.address, # porque es transferencia interna
          "issuer_ruc": guia_series.invoicer.ruc,
          "issuer_razon_social": guia_series.invoicer.razon_social,
          "issuer_address": guia_series.invoicer.address,
          "origin_address": @stock_transfer.origin_warehouse.location.address,
          "destination_address": @stock_transfer.destination_warehouse.location.address,
          "recipient_name": @stock_transfer.destination_warehouse.name,
          "recipient_document_type": "6", # RUC
          "recipient_document_number": guia_series.invoicer.ruc, # Using the same RUC as issuer for internal transfers
          "transfer_reason": "01", # 01 is the code for Sale
          "transport_mode": "01", # 01 is the code for Public transport
          "efact_client_token": guia_series.invoicer.einvoice_api_key,
          "envio_fecha_inicio_traslado": @stock_transfer.date_guia&.strftime("%d-%m-%Y") || Time.current.strftime("%d-%m-%Y"),
          "envio_descripcion_traslado": @stock_transfer.comments || "Transferencia de stock #{@stock_transfer.custom_id}",
          "envio_peso_bruto_total": 10,
          "envio_unidad_medida_peso": "KGM",
          "envio_modalidad_traslado": "02",
          "partida_ubigeo": "030109",
          "partida_direccion": @stock_transfer.origin_warehouse.location.address,
          "llegada_ubigeo": "030109",
          "llegada_direccion": @stock_transfer.destination_warehouse.location.address,
          "observaciones": @stock_transfer.comments || "Transferencia de stock #{@stock_transfer.custom_id}",
          "move_lines": guia_lines,
          # Additional fields required by Nubefact
          "transportista_indicador_m1l": nil,
          "transportista_tipo_doc":
            if @stock_transfer.transportista&.ruc?
              "6" # RUC
            elsif @stock_transfer.transportista&.dni?
              "1" # DNI
            else
              "6" # Default to RUC as fallback
            end,
          "transportista_num_doc":
            if @stock_transfer.transportista&.ruc?
              @stock_transfer.transportista.ruc_number
            elsif @stock_transfer.transportista&.dni?
              @stock_transfer.transportista.dni_number
            else
              guia_series.invoicer.ruc # Fallback to invoicer
            end,
          "transportista_razon_social":
            if @stock_transfer.transportista&.ruc?
              @stock_transfer.transportista.razon_social
            elsif @stock_transfer.transportista&.dni?
              "#{@stock_transfer.transportista.first_name} #{@stock_transfer.transportista.last_name}"
            else
              guia_series.invoicer.razon_social # Fallback to invoicer
            end,
          "transportista_numero_mtc": nil,
          "transportista_chofer_tipo_doc": "1", # Always DNI for driver
          "transportista_chofer_num_doc":
            if @stock_transfer.transportista&.dni?
              @stock_transfer.transportista.dni_number
            else
              "09344556" # Default fallback
            end,
          "transportista_chofer_num_licencia":
            if @stock_transfer.transportista&.dni?
              @stock_transfer.transportista.license_number
            else
              "Q09344556" # Default fallback
            end,
          "transportista_chofer_nombres":
            if @stock_transfer.transportista&.dni?
              @stock_transfer.transportista.first_name
            else
              "Augusto" # Default fallback
            end,
          "transportista_chofer_apellidos":
            if @stock_transfer.transportista&.dni?
              @stock_transfer.transportista.last_name
            else
              "Samame Barrientos" # Default fallback
            end,
          "transportista_placa": @stock_transfer.transportista&.vehicle_plate
        }

        response = Integrations::Nubefact.new.emitir_guia(guia_data.to_json)
        Rails.logger.info("Guia Response: #{response.parsed_response}")
        Rails.logger.info("Guia Response text: #{response.parsed_response["response_text"]}")

        guia = Guia.new(
          stock_transfer: @stock_transfer,
          custom_id: "#{guia_data[:serie]}-#{guia_data[:correlativo]}",
          guia_series: guia_series,
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

      def determine_codigo_guia
        # "01" - Venta
        # "02" - Compra
        "04" # Interno
      end

      def determine_guia_series_for_stock_transfer
        found_guia_series = GuiaSeriesMapping.find_by!(location: @stock_transfer.origin_warehouse).guia_series

        if found_guia_series.blank?
          raise "No active guia series found for guia_remision stock transfer origin warehouse location"
        end

        found_guia_series
      end
    end
  end
end
