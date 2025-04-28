module Services
  module Sales
    class OrderInvoiceService
      def initialize(order, options = {})
        @order = order
        @options = options
      end

      def send_invoice_email
        invoice_link = @order.universal_invoice_link
        ErpMailer.send_user_invoice(@order, @order.user, invoice_link).deliver_later
      end

      def create_invoices
        # Return early if nota_de_venta is true
        return nil if @order.nota_de_venta

        invoice_data = determine_order_invoices_matrix

        if [ "B002", "B003" ].include?(invoice_data&.invoice_series&.prefix) && ENV["CURRENT_ORGANIZATION"] == "jardindelzen"
          # ignore RUS boletas for now
          return nil
        end

        # dont generate einvoices for pedidosya and rappi orders
        if [ "pedidosya", "rappi" ].include?(@order&.payments&.first&.payment_method&.name) && ENV["CURRENT_ORGANIZATION"] == "jardindelzen"
          return nil
        end

        invoice_line_ids = []

        # Use exact tax rate
        tax_rate = 0.18

        # Track the running total of tax amounts
        running_tax_total = 0
        exonerados_total = 0

        @order.order_items.each_with_index do |order_line, index|
          # Calculate unit prices without early rounding
          unit_price_with_tax = order_line.price.to_f

          # Check if product is inafecto (tax exempt)
          if order_line.product.inafecto
            # For inafecto products, tax rate is 0
            unit_price_no_tax = unit_price_with_tax
            line_price_total_with_tax = unit_price_with_tax * order_line.quantity.to_f
            line_price_total_no_tax = line_price_total_with_tax
            line_tax_amount = 0
            exonerados_total += line_price_total_with_tax
          else
            # For regular products, apply normal tax rate
            unit_price_no_tax = unit_price_with_tax / (1 + tax_rate)

            # Calculate line totals
            quantity = order_line.quantity.to_f
            line_price_total_with_tax = unit_price_with_tax * quantity
            line_price_total_no_tax = unit_price_no_tax * quantity

            # Calculate tax amount precisely - don't round yet
            line_tax_amount = line_price_total_with_tax - line_price_total_no_tax

            # Add to running total
            running_tax_total += line_tax_amount
          end

          # Calculate discount
          quantity = order_line.quantity.to_f
          line_discount = order_line.discounted_price.to_f == 0 ? 0 :
                         (unit_price_with_tax - order_line.discounted_price.to_f) * quantity

          # Log the calculations for debugging
          Rails.logger.info("Product: #{order_line.product.name}, Line: #{index+1}, Quantity: #{quantity}, " +
                           "Line Tax: #{line_tax_amount.round(6)}, Inafecto: #{order_line.product.inafecto}")

          invoice_line_ids << {
            "name": order_line.product.name,
            "description": order_line.product.description,
            "product_id": order_line.product.custom_id,
            "quantity": quantity.round(0),
            "unit_price_no_tax": unit_price_no_tax.round(6),
            "unit_price_with_tax": unit_price_with_tax,
            "price_subtotal": line_price_total_no_tax.round(6),
            "line_price_total_no_tax": line_price_total_no_tax.round(6),
            "line_price_total_with_tax": line_price_total_with_tax.round(6),
            "line_tax_amount": line_tax_amount.round(6),
            "line_discount": line_discount,
            "tax_id": order_line.product.inafecto ? "INAFECTO" : "IGV"
          }
        end

        # Use the calculated total tax amount
        total_tax_amount = running_tax_total

        # Log the final values
        Rails.logger.info("Sum of Line Tax Amounts: #{running_tax_total.round(6)}")
        Rails.logger.info("Total Tax Amount: #{total_tax_amount}")

        invoice_data_hash = {
          "date_invoice": @options[:date_invoice] || Time.current.strftime("%Y-%m-%d"),
          "invoice_number": invoice_data.invoice_series.next_invoice_number,
          "order_custom_id": @order.custom_id,
          "currency_id": @order.currency,
          "invoicer_ruc": invoice_data.invoicer.ruc,
          "invoicer_razon_social": invoice_data.invoicer.razon_social,
          "customer_ruc": @order.wants_factura ? @order.customer.customer.factura_ruc : @order.customer.customer.doc_id,
          "customer_comprobante_tipo_catalog_6": invoice_customer_doc_type,
          "customer_name": @order.wants_factura ? @order.customer.customer.factura_razon_social : @order.customer.name,
          "customer_address": @order.wants_factura ? @order.customer.customer.factura_direccion : (@order.customer.customer.dni_address.present? ? @order.customer.customer.dni_address : "Sin dirección"),
          "payment_term_id": determine_payment_term_id(invoice_data.payment_method),
          "payment_credit_days": determine_payment_term_id(invoice_data.payment_method) == 1 ? 0 : 30,
          "order_total": (@order.total_price.to_f).round(6),
          "exonerados_total": exonerados_total.round(6),
          "order_discount": (@order.total_discount.to_f).round(6),
          "tax_line_ids": [ {
            "tax_id": "IGV",
            "amount": total_tax_amount
          } ],
          "invoice_line_ids": invoice_line_ids,
          "email": @order.customer.email,
          "invoice_type": invoice_data.invoice_type,
          "efact_client_token": invoice_data.invoicer.einvoice_api_key,
          "comments": @order.einvoice_comments
        }

        if @order.servicio_transporte
          invoice_data_hash["detraccion_use_valor_referencial"] = @order.servicio_transporte_hash["detraccion_use_valor_referencial"]
          invoice_data_hash["ubigeo_origen"] = @order.servicio_transporte_hash["ubigeo_origen"]
          invoice_data_hash["ubigeo_destino"] = @order.servicio_transporte_hash["ubigeo_destino"]
          invoice_data_hash["direccion_origen"] = @order.servicio_transporte_hash["direccion_origen"]
          invoice_data_hash["direccion_destino"] = @order.servicio_transporte_hash["direccion_destino"]
          invoice_data_hash["guia_remision"] = @order.servicio_transporte_hash["guia_remision"]
          invoice_data_hash["guia_transportista"] = @order.servicio_transporte_hash["guia_transportista"]
          invoice_data_hash["valor_referencial_carga_efectiva"] = @order.servicio_transporte_hash["valor_carga_efectiva"]
          invoice_data_hash["valor_referencial_carga_util"] = @order.servicio_transporte_hash["valor_carga_util"]
          invoice_data_hash["valor_referencial_transporte"] = @order.servicio_transporte_hash["valor_servicio"]
          invoice_data_hash["detalle_viaje"] = @order.servicio_transporte_hash["descripcion"]
          invoice_data_hash["reduce_detraccion_cuota"] = @order.servicio_transporte_hash["restar_detraccion"]
        end

        response = Integrations::Nubefact.new.emitir_comprobante(invoice_data_hash.to_json)
        Rails.logger.info("Response: #{response.parsed_response}")
        Rails.logger.info("Response text: #{response.parsed_response["response_text"]}")

        invoice = Invoice.new(
            order: @order,
            custom_id: invoice_data.invoice_series.next_invoice_number,
            invoice_series: invoice_data.invoice_series,
            payment_method: invoice_data.payment_method,
            amount: invoice_data.amount,
            currency: invoice_data.currency,
            invoice_type: invoice_data.invoice_series.comprobante_type,
            invoice_sunat_sent_text: invoice_data_hash.to_json,
            invoice_sunat_response: response.parsed_response,
            invoice_url: response.parsed_response["response_url"]
          )
        if response.parsed_response["response_text"]
          if response.parsed_response["response_text"] == "OK"
            invoice.sunat_status = "sunat_success"
            invoice.status = "issued"
          else
            invoice.sunat_status = "sunat_error"
            invoice.status = "issued"
          end
        else
          invoice.sunat_status = "application_error"
        end
        invoice.save
        invoice
      end

      def determine_payment_term_id(payment_method)
        case payment_method.name
        when "credit"
          2
        else
          1
        end
      end

      def determine_order_invoices_matrix
        # in case there are multiple payment methods, we use the invoicer that matches the first payment method found (usually card)
        if @order.payments.count > 1
          card_payment_method = PaymentMethod.find_by(name: "card")&.id
          priority_payment = @order.payments.find_by(payment_method_id: card_payment_method)
          if priority_payment.blank?
            priority_payment = @order.payments.first
          end
        else
          priority_payment = @order.payments.first
        end
        invoice_series_ids = InvoiceSeriesMapping.where(location_id: @order.location_id, payment_method_id: priority_payment.payment_method_id).pluck(:invoice_series_id)
        invoice_series = InvoiceSeries.where(id: invoice_series_ids)
        if @order.wants_factura
          invoice_series = invoice_series.where(comprobante_type: "factura")
        else
          invoice_series = invoice_series.where(comprobante_type: "boleta")
        end
        if invoice_series.count == 1
          invoice_series = invoice_series.first
        else
          # TODO handle case where no invoice series matches exact payment method, so you need to fall back to default
          invoice_series_ids = InvoiceSeriesMapping.where(location_id: @order.location_id, default: true).pluck(:invoice_series_id)
          invoice_series = InvoiceSeries.where(id: invoice_series_ids)
          if @order.wants_factura
            invoice_series = invoice_series.where(comprobante_type: "factura")
          else
            invoice_series = invoice_series.where(comprobante_type: "boleta")
          end
          if invoice_series.present?
            invoice_series = invoice_series.first
          else
            raise "No matching or default invoice series found for order #{@order.id}, location #{@order.location_id}, payment method #{priority_payment&.payment_method_id}"
          end
        end

        invoice_data = OpenStruct.new(
          invoicer: invoice_series.invoicer,
          invoice_series: invoice_series,
          payment_method: priority_payment.payment_method,
          amount: @order.total_price,
          currency: @order.currency,
          location: @order.location,
          order: @order
        )
        invoice_data
      end

      def void_invoice
        return if @order.invoice_list.blank?

        # Split the comma-separated invoice_list string into an array of invoice custom IDs
        invoice_custom_ids = @order.invoice_list.split(", ").map(&:strip)

        invoice_custom_ids.each do |invoice_custom_id|
          # Find the invoice by custom_id
          invoice = Invoice.find_by(custom_id: invoice_custom_id)

          if invoice && invoice.status == "issued"
            # send to sunat and void invoice here. If successful, update invoice status to voided
            void_invoice_data_hash = {
              "number": invoice.custom_id,
              "efact_client_token": invoice.invoicer.einvoice_api_key,
              "state": "cancel"
            }

            response = Integrations::Nubefact.new.anular_comprobante(void_invoice_data_hash.to_json)
            Rails.logger.info("Response: #{response.parsed_response}")
            Rails.logger.info("Response text: #{response.parsed_response["response_text"]}")
            if response.parsed_response["response_text"] == "OK"
              invoice.update(status: "voided", void_url: response.parsed_response["response_url"], void_sunat_response: response.parsed_response)
            else
              invoice.update(void_sunat_response: response.parsed_response)
              Rails.logger.error("Invoice voiding failed: #{response.parsed_response["response_text"]}")
            end
          else
            Rails.logger.error("Invoice with custom_id #{invoice_custom_id} not found")
          end
        end
      end

      private

      def invoice_customer_doc_type
        if @order.wants_factura
          if @order.customer.customer.doc_type == "passport"
            "7"
          else
            "6"
          end
        else
          Customer.doc_types[@order.customer.customer.doc_type]
        end
      end
    end
  end
end
