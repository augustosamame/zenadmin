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
        invoice_data = determine_order_invoices_matrix

        if [ "B002", "B003" ].include?(invoice_data&.invoice_series&.prefix)
          # ignore RUS boletas for now
          return nil
        end

        # dont generate einvoices for pedidosya and rappi orders
        if [ "pedidosya", "rappi" ].include?(@order&.payments&.first&.payment_method&.name)
          return nil
        end

        invoice_line_ids = []
        total_tax_amount = 0

        @order.order_items.each do |order_line|
          # Calculate unit prices without early rounding
          unit_price_with_tax = order_line.price.to_f
          unit_price_no_tax = (unit_price_with_tax / 1.18)

          # Calculate line totals
          quantity = order_line.quantity.to_f
          line_price_total_with_tax = unit_price_with_tax * quantity
          line_price_total_no_tax = unit_price_no_tax * quantity

          # Calculate tax amount precisely
          line_tax_amount = (line_price_total_with_tax - line_price_total_no_tax).round(2)
          total_tax_amount += line_tax_amount

          # Calculate discount
          line_discount = order_line.discounted_price.to_f == 0 ? 0 :
                         (unit_price_with_tax - order_line.discounted_price.to_f) * quantity

          invoice_line_ids << {
            "name": order_line.product.name,
            "description": order_line.product.description,
            "product_id": order_line.product.custom_id,
            "quantity": quantity.round(0),
            "unit_price_no_tax": unit_price_no_tax.round(2),
            "unit_price_with_tax": unit_price_with_tax,
            "price_subtotal": line_price_total_no_tax.round(2),
            "line_price_total_no_tax": line_price_total_no_tax.round(2),
            "line_price_total_with_tax": line_price_total_with_tax.round(2),
            "line_tax_amount": line_tax_amount,
            "line_discount": line_discount,
            "tax_id": "IGV"
          }
        end

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
          "customer_address": @order.wants_factura ? @order.customer.customer.factura_direccion : "Sin dirección",
          "payment_term_id": 1,
          "payment_credit_days": 0,
          "order_total": (@order.total_price.to_f).round(2),
          "order_discount": (@order.total_discount.to_f / 1.18).round(2),
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
