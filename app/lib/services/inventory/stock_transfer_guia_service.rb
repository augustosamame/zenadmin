module Services
  module Inventory
    class StockTransferGuiaService
      def initialize(object_origin, object_id, options = {})
        case object_origin
        when "stock_transfer", "stock_transfer_venta"
          @stock_transfer = StockTransfer.find(object_id)
        when "venta"
          @order = Order.find(object_id)
        when "compra"
          # @purchase = Purchase.find(object_id)
        when "servicio_transporte"
          @order = Order.find(object_id)
        end
        @options = options
        @object_origin = object_origin
        @object_id = object_id
      end

      def create_guia(guia_params = {})
        case @object_origin
        when "stock_transfer"
          result = create_guia_from_stock_transfer(guia_params, sale: false)
        when "stock_transfer_venta"
          result = create_guia_from_stock_transfer(guia_params, sale: true)
        when "venta"
          result = create_guia_from_order(guia_params)
        when "compra"
          # @purchase = Purchase.find(@object_id)
        when "servicio_transporte"
          result = create_guia_de_transporte_from_order(guia_params)
        end
      end

      def create_guia_from_stock_transfer(guia_params = {}, sale: false)
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
            "product_uom": product.unit_of_measure&.sunat_code || "NIU",
            "weight": product.weight || 1.0
          }
        end

        # Extract modal params or fallback to defaults

        partida_direccion = guia_params[:origin_address] || @stock_transfer&.origin_warehouse&.location&.address
        partida_ubigeo = guia_params[:origin_ubigeo] || @stock_transfer&.origin_warehouse&.location&.ubigeo
        llegada_direccion = guia_params[:destination_address] || @stock_transfer&.destination_warehouse&.location&.address
        llegada_ubigeo = guia_params[:destination_ubigeo] || @stock_transfer&.destination_warehouse&.location&.ubigeo
        envio_peso_bruto_total = guia_params[:envio_peso_bruto_total] || 10
        envio_num_bultos = guia_params[:envio_num_bultos] || 1
        observaciones = guia_params[:comments] || @stock_transfer.comments || "Transferencia de stock #{@stock_transfer.custom_id}"
        transportista = guia_params[:transportista] || @stock_transfer.transportista
        # transportista may be an ID, so fetch if needed
        if transportista.is_a?(String) || transportista.is_a?(Integer)
          transportista = Transportista.find_by(id: transportista)
        end

        # Map transportista fields
        transportista_fields = map_transportista_fields(transportista, guia_series)

        # Extract destination client for sale transfers
        destination_client = nil
        if sale
          destination_client = User.find(@stock_transfer.customer_user_id)
        end

        # Prepare the guia data
        guia_data = {
          "guia_de_remision": true,
          "serie": guia_series.prefix,
          "envio_codigo_traslado": sale ? "01" : "04", # 01 is the code for Sale, 04 for internal
          "guia_tipo_doc_sent_to_efact": guia_series.guia_type == "guia_remision" ? "remitente" : "transportista",
          "tipo_doc": "09",
          "date_guia": @stock_transfer.date_guia&.strftime("%d-%m-%Y") || Time.current.strftime("%d-%m-%Y"),
          "datetime_guia": @stock_transfer.date_guia&.strftime("%d-%m-%Y %H:%M:%S") || Time.current.strftime("%d-%m-%Y %H:%M:%S"),
          "correlativo": guia_series.next_invoice_number.split("-").last,
          "stock_transfer_custom_id": @stock_transfer.custom_id,
          "destinatario_tipo_doc": sale ? (destination_client.customer.wants_factura? ? "6" : "1") : "6",
          "destinatario_ruc": sale ? (destination_client.customer.wants_factura? ? destination_client.customer.factura_ruc : destination_client.customer.doc_id) : guia_series.invoicer.ruc,
          "destinatario_razon_social": sale ? (destination_client.customer.wants_factura? ? destination_client.customer.factura_razon_social : destination_client.name) : guia_series.invoicer.razon_social,
          "destinatario_direccion": sale ? destination_client.address : guia_series.invoicer.address,
          "issuer_ruc": guia_series.invoicer.ruc,
          "issuer_razon_social": guia_series.invoicer.razon_social,
          "efact_client_token": guia_series.invoicer.einvoice_api_key,
          "envio_fecha_inicio_traslado": @stock_transfer.date_guia&.strftime("%d-%m-%Y") || Time.current.strftime("%d-%m-%Y"),
          "envio_descripcion_traslado": observaciones,
          "envio_peso_bruto_total": envio_peso_bruto_total,
          "envio_unidad_medida_peso": "KGM",
          "envio_num_bultos": envio_num_bultos,
          "envio_modalidad_traslado": transportista_fields[:transportista_type] == "privado" ? "02" : "01",
          "partida_ubigeo": partida_ubigeo,
          "partida_direccion": partida_direccion,
          "llegada_ubigeo": llegada_ubigeo,
          "llegada_direccion": llegada_direccion,
          "observaciones": observaciones,
          "move_lines": guia_lines,
          # Additional fields required by Nubefact
          "transportista_indicador_m1l": transportista_fields[:m1l_indicator],
          "transportista_tipo_doc": transportista_fields[:tipo_doc],
          "transportista_num_doc": transportista_fields[:num_doc],
          "transportista_razon_social": transportista_fields[:razon_social],
          "transportista_numero_mtc": transportista_fields[:numero_mtc],
          "transportista_chofer_tipo_doc": "1",
          "transportista_chofer_num_doc": transportista_fields[:chofer_num_doc],
          "transportista_chofer_num_licencia": transportista_fields[:chofer_num_licencia],
          "transportista_chofer_nombres": transportista_fields[:chofer_nombres],
          "transportista_chofer_apellidos": transportista_fields[:chofer_apellidos],
          "transportista_placa": transportista_fields[:placa]
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

      def create_guia_from_order(guia_params = {})
        # Get the order's location to determine the guia series
        location = @order.location
        guia_series_mapping = GuiaSeriesMapping.joins(:guia_series)
                                              .where(location: location)
                                              .where(guia_series: { guia_type: :guia_remision })
                                              .first

        if guia_series_mapping.blank?
          raise "No active guia series mapping found for guia_remision order location"
        end

        guia_series = guia_series_mapping.guia_series

        # Prepare line items
        guia_lines = []
        @order.order_items.each do |order_item|
          product = order_item.product
          next unless product

          guia_lines << {
            "name": product.name,
            "description": product.description,
            "product_id": product.custom_id,
            "quantity": order_item.quantity,
            "product_uom": product.unit_of_measure&.sunat_code || "NIU",
            "weight": product.weight || 1.0
          }
        end

        # Extract modal params or fallback to defaults
        partida_direccion = guia_params[:origin_address] || @order.location&.address
        partida_ubigeo = guia_params[:origin_ubigeo] || @order.location&.ubigeo
        llegada_direccion = guia_params[:destination_address] || @order.user&.address
        llegada_ubigeo = guia_params[:destination_ubigeo] || @order.user&.ubigeo
        envio_peso_bruto_total = guia_params[:envio_peso_bruto_total] || 10
        envio_num_bultos = guia_params[:envio_num_bultos] || 1
        observaciones = guia_params[:comments] || @order.seller_note || "Venta #{@order.custom_id}"
        transportista = guia_params[:transportista] || @order.transportista

        # transportista may be an ID, so fetch if needed
        if transportista.is_a?(String) || transportista.is_a?(Integer)
          transportista = Transportista.find_by(id: transportista)
        end

        # Map transportista fields
        transportista_fields = map_transportista_fields(transportista, guia_series)

        # Prepare the guia data
        guia_data = {
          "guia_de_remision": true,
          "serie": guia_series.prefix,
          "envio_codigo_traslado": "01", # 01 for sales
          "guia_tipo_doc_sent_to_efact": guia_series.guia_type == "guia_remision" ? "remitente" : "transportista",
          "tipo_doc": "09",
          "date_guia": Time.current.strftime("%d-%m-%Y"),
          "datetime_guia": Time.current.strftime("%d-%m-%Y %H:%M:%S"),
          "correlativo": guia_series.next_invoice_number.split("-").last,
          "order_custom_id": @order.custom_id,
          "destinatario_tipo_doc": @order.customer.customer.wants_factura? ? "6" : "1",
          "destinatario_ruc": @order.customer.customer.wants_factura? ? @order.customer.customer.factura_ruc : @order.customer.customer.doc_id,
          "destinatario_razon_social": @order.customer.customer.wants_factura? ? @order.customer.customer.factura_razon_social : @order.customer.name,
          "destinatario_direccion": @order.customer.customer.wants_factura? ? @order.customer.customer.factura_direccion : @order.customer.customer.dni_address,
          "issuer_ruc": guia_series.invoicer.ruc,
          "issuer_razon_social": guia_series.invoicer.razon_social,
          "efact_client_token": guia_series.invoicer.einvoice_api_key,
          "envio_fecha_inicio_traslado": Time.current.strftime("%d-%m-%Y"),
          "envio_descripcion_traslado": observaciones,
          "envio_peso_bruto_total": envio_peso_bruto_total,
          "envio_unidad_medida_peso": "KGM",
          "envio_num_bultos": envio_num_bultos,
          "envio_modalidad_traslado": transportista_fields[:transportista_type] == "privado" ? "02" : "01",
          "partida_ubigeo": partida_ubigeo,
          "partida_direccion": partida_direccion,
          "llegada_ubigeo": llegada_ubigeo,
          "llegada_direccion": llegada_direccion,
          "observaciones": observaciones,
          "move_lines": guia_lines,
          # Additional fields required by Nubefact
          "transportista_indicador_m1l": transportista_fields[:m1l_indicator],
          "transportista_tipo_doc": transportista_fields[:tipo_doc],
          "transportista_num_doc": transportista_fields[:num_doc],
          "transportista_razon_social": transportista_fields[:razon_social],
          "transportista_numero_mtc": transportista_fields[:numero_mtc],
          "transportista_chofer_tipo_doc": "1",
          "transportista_chofer_num_doc": transportista_fields[:chofer_num_doc],
          "transportista_chofer_num_licencia": transportista_fields[:chofer_num_licencia],
          "transportista_chofer_nombres": transportista_fields[:chofer_nombres],
          "transportista_chofer_apellidos": transportista_fields[:chofer_apellidos],
          "transportista_placa": transportista_fields[:placa]
        }

        response = Integrations::Nubefact.new.emitir_guia(guia_data.to_json)
        Rails.logger.info("Guia Response: #{response.parsed_response}")
        Rails.logger.info("Guia Response text: #{response.parsed_response["response_text"]}")

        guia = Guia.new(
          order_id: @order.id,
          custom_id: "#{guia_data[:serie]}-#{guia_data[:correlativo]}",
          guia_series: guia_series,
          amount: @order.total_products,
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

      def create_guia_de_transporte_from_order(guia_params = {})
        # Get the order's location to determine the guia series
        location = @order.location
        guia_series_mapping = GuiaSeriesMapping.joins(:guia_series)
                                              .where(location: location)
                                              .where(guia_series: { guia_type: :guia_transporte })
                                              .first

        if guia_series_mapping.blank?
          raise "No active guia series mapping found for guia_transporte order location"
        end

        guia_series = guia_series_mapping.guia_series

        # Extract modal params or fallback to defaults
        partida_direccion = guia_params[:origin_address] || @order.location&.address
        partida_ubigeo = guia_params[:origin_ubigeo] || @order.location&.ubigeo
        llegada_direccion = guia_params[:destination_address] || @order.user&.address
        llegada_ubigeo = guia_params[:destination_ubigeo] || @order.user&.ubigeo
        envio_peso_bruto_total = guia_params[:envio_peso_bruto_total] || 10
        envio_num_bultos = guia_params[:envio_num_bultos] || 1
        observaciones = guia_params[:comments] || @order.seller_note || "Venta #{@order.custom_id}"
        transportista = guia_params[:transportista] || @order.transportista

        guia_lines = {
          "name": "Servicio de Transporte",
          "description": "Servicio de Transporte",
          "product_id": "Servicio de Transporte",
          "quantity": 1,
          "product_uom": "NIU",
          "weight": envio_peso_bruto_total
        }

        # transportista may be an ID, so fetch if needed
        if transportista.is_a?(String) || transportista.is_a?(Integer)
          transportista = Transportista.find_by(id: transportista)
        end

        # Map transportista fields
        transportista_fields = map_transportista_fields(transportista, guia_series)

        # Prepare the guia data
        guia_data = {
          "guia_de_remision": true,
          "serie": guia_series.prefix,
          "envio_codigo_traslado": "01", # 01 for sales
          "guia_tipo_doc_sent_to_efact": guia_series.guia_type == "guia_remision" ? "remitente" : "transportista",
          "tipo_doc": "08",
          "date_guia": Time.current.strftime("%d-%m-%Y"),
          "datetime_guia": Time.current.strftime("%d-%m-%Y %H:%M:%S"),
          "correlativo": guia_series.next_invoice_number.split("-").last,
          "order_custom_id": @order.custom_id,
          "destinatario_tipo_doc": @order.customer.customer.wants_factura? ? "6" : "1",
          "destinatario_ruc": @order.customer.customer.wants_factura? ? @order.customer.customer.factura_ruc : @order.customer.customer.doc_id,
          "destinatario_razon_social": @order.customer.customer.wants_factura? ? @order.customer.customer.factura_razon_social : @order.customer.name,
          "destinatario_direccion": @order.customer.customer.wants_factura? ? @order.customer.customer.factura_direccion : @order.customer.customer.dni_address,
          "issuer_ruc": guia_series.invoicer.ruc,
          "issuer_razon_social": guia_series.invoicer.razon_social,
          "efact_client_token": guia_series.invoicer.einvoice_api_key,
          "envio_fecha_inicio_traslado": Time.current.strftime("%d-%m-%Y"),
          "envio_descripcion_traslado": observaciones,
          "envio_peso_bruto_total": envio_peso_bruto_total,
          "envio_unidad_medida_peso": "KGM",
          "envio_num_bultos": envio_num_bultos,
          "envio_modalidad_traslado": transportista_fields[:transportista_type] == "privado" ? "02" : "01",
          "partida_ubigeo": partida_ubigeo,
          "partida_direccion": partida_direccion,
          "llegada_ubigeo": llegada_ubigeo,
          "llegada_direccion": llegada_direccion,
          "observaciones": observaciones,
          "move_lines": guia_lines,
          # Additional fields required by Nubefact
          "transportista_indicador_m1l": transportista_fields[:m1l_indicator],
          "transportista_tipo_doc": transportista_fields[:tipo_doc],
          "transportista_num_doc": transportista_fields[:num_doc],
          "transportista_razon_social": transportista_fields[:razon_social],
          "transportista_numero_mtc": transportista_fields[:numero_mtc],
          "transportista_chofer_tipo_doc": "1",
          "transportista_chofer_num_doc": transportista_fields[:chofer_num_doc],
          "transportista_chofer_num_licencia": transportista_fields[:chofer_num_licencia],
          "transportista_chofer_nombres": transportista_fields[:chofer_nombres],
          "transportista_chofer_apellidos": transportista_fields[:chofer_apellidos],
          "transportista_placa": transportista_fields[:placa]
        }

        response = Integrations::Nubefact.new.emitir_guia(guia_data.to_json)
        Rails.logger.info("Guia Response: #{response.parsed_response}")
        Rails.logger.info("Guia Response text: #{response.parsed_response["response_text"]}")

        guia = Guia.new(
          order_id: @order.id,
          custom_id: "#{guia_data[:serie]}-#{guia_data[:correlativo]}",
          guia_series: guia_series,
          amount: @order.total_products,
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

      def determine_guia_series_for_stock_transfer
        found_guia_series = GuiaSeriesMapping.joins(:guia_series)
                                              .where(location: @stock_transfer.origin_warehouse, guia_series: { guia_type: :guia_remision })
                                              .first

        if found_guia_series.blank?
          raise "No active guia series mapping found for guia_remision stock transfer origin warehouse location"
        end

        found_guia_series.guia_series
      end

      private

      def map_transportista_fields(transportista, guia_series)
        fields = {
          tipo_doc: nil,
          num_doc: nil,
          razon_social: nil,
          chofer_num_doc: nil,
          chofer_num_licencia: nil,
          chofer_nombres: nil,
          chofer_apellidos: nil,
          placa: nil,
          transportista_type: nil,
          m1l_indicator: nil,
          numero_mtc: nil
        }

        if transportista&.ruc?
          fields[:tipo_doc] = "6"
          fields[:num_doc] = transportista.ruc_number
          fields[:razon_social] = transportista.razon_social
        elsif transportista&.dni?
          fields[:tipo_doc] = "1"
          fields[:num_doc] = transportista.dni_number
          fields[:razon_social] = "#{transportista.first_name} #{transportista.last_name}"
        else
          fields[:tipo_doc] = "6"
          fields[:num_doc] = guia_series.invoicer.ruc
          fields[:razon_social] = guia_series.invoicer.razon_social
        end

        fields[:transportista_type] = transportista&.transportista_type

        fields[:chofer_num_doc] = transportista.dni_number
        fields[:chofer_num_licencia] = transportista.license_number
        fields[:chofer_nombres] = transportista.first_name
        fields[:chofer_apellidos] = transportista.last_name
        fields[:placa] = transportista&.vehicle_plate
        fields[:m1l_indicator] = transportista&.m1l_indicator
        fields[:numero_mtc] = transportista&.numero_mtc

        fields
      end
    end
  end
end
