class Services::Sales::OrderVoidService
  def initialize(order, current_user, reason = nil)
    @order = order
    @current_user = current_user
    @reason = reason
  end

  def void
    success = false
    message = nil
    voided_order = nil

    Audited.auditing_enabled = false

    ActiveRecord::Base.transaction do
      begin
        # Store order data before destroying
        order_data = serialize_order_data
        invoice_list = @order.invoices.where(sunat_status: "sunat_success").map { |invoice| invoice.custom_id }.join(", ")

        voided_order = VoidedOrder.create!(
          original_order_id: @order.id.to_s,
          original_order_order_date: @order.order_date,
          original_order_custom_id: @order.custom_id,
          location_id: @order.location_id,
          user_id: @current_user.id,
          original_order_data: order_data,
          voided_at: Time.current,
          void_reason: @reason,
          invoice_list: invoice_list
        )

        unless Location.exists?(@order.location_id) && User.exists?(@current_user.id)
          raise ActiveRecord::RecordNotFound, "Location or User not found"
        end

        # 1. Void the invoice through Einvoice service
        # if @order.invoice.present?
        #  einvoice_response = Services::Einvoice::VoidInvoiceService.new(@order.invoice).void
        #  raise ActiveRecord::Rollback unless einvoice_response.success?
        # end

        # 2. Destroy commission if exists
        @order.commissions.destroy_all if @order.commissions.any?

        # 3. Destroy payments and their cashier transactions
        @order.payments.each do |payment|
          payment.cashier_transaction.destroy! if payment.cashier_transaction.present?
          payment.destroy!
        end

        # 4. Return stock to warehouse inventory
        warehouse = @order.location.warehouses.first
        @order.order_items.each do |order_item|
          inventory = warehouse.warehouse_inventories.find_by(product_id: order_item.product_id)
          new_stock = inventory.stock + order_item.quantity
          inventory.update!(stock: new_stock)
        end

        # 6. Destroy order items
        @order.order_items.destroy_all

        # 7. Finally destroy the order
        @order.destroy!

        success = true
        message = "Orden #{@order.custom_id} anulada exitosamente"
      rescue ActiveRecord::RecordNotFound => e
        message = "No se encontró algún registro necesario: #{e.message}"
        raise ActiveRecord::Rollback
      rescue ActiveRecord::RecordInvalid => e
        message = "Error de validación: #{e.record.errors.full_messages.join(', ')}"
        raise ActiveRecord::Rollback
      rescue StandardError => e
        message = "Error inesperado al anular la orden: #{e.message}"
        raise ActiveRecord::Rollback
      end
    end

    Audited.auditing_enabled = true

    if success
      VoidEinvoice.perform_async(voided_order.id)
    end

    return success, message
  end

  private

  def serialize_order_data
    customer = if @order.customer.present?
      {
        id: @order.customer.id,
        full_name: @order.customer.name,
        email: @order.customer.email,
        phone: @order.customer.phone,
        dni: @order.customer.customer.doc_id,
        ruc: @order.customer.customer.wants_factura ? @order.customer.customer.factura_ruc : nil,
        business_name: @order.customer.customer.wants_factura ? @order.customer.customer.factura_razon_social : nil
      }
    end
    {
      order: @order.as_json,
      customer: customer,
      order_items: @order.order_items.as_json,
      payments: @order.payments.map { |p|
        {
          payment: p.as_json,
          cashier_transaction: p.cashier_transaction&.as_json
        }
      },
      commissions: @order.commissions.as_json,
      invoices: @order.invoices.as_json
    }
  end
end
