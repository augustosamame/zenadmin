class Services::Sales::OrderItemEditService
  def initialize(order)
    @order = order
    @original_total = @order.total_price_cents
  end

  def update_order_items(order_items_params)
    ActiveRecord::Base.transaction do
      total_cents = 0

      order_items_params.each do |id, item_params|
        order_item = @order.order_items.find(id)
        original_quantity = order_item.quantity

        # Update order item
        order_item.update!(
          product_id: item_params[:product_id],
          price_cents: item_params[:price_cents],
          quantity: item_params[:quantity]
        )

        # Update warehouse inventory
        update_warehouse_inventory(
          order_item.product_id,
          original_quantity,
          item_params[:quantity].to_i
        )

        total_cents += order_item.price_cents * order_item.quantity
      end

      # Calculate difference between original and new total
      difference_cents = total_cents - @original_total

      # Update order total
      @order.update!(total_price_cents: total_cents)

      # Update payment based on count
      if @order.payments.any?
        adjust_payments_proportionally(difference_cents)
      end

      if @order.commissions.any?
        adjust_commissions_proportionally(difference_cents)
      end
    end
  end

  private

  def adjust_payments_proportionally(difference_cents)
    payments = @order.payments
    total_payments_cents = payments.sum(:amount_cents)

    payments.each do |payment|
      # Calculate the proportion this payment represents of the total
      payment_ratio = payment.amount_cents.to_f / total_payments_cents

      # Calculate this payment's share of the difference
      adjustment = (difference_cents * payment_ratio).round

      # Calculate new amount ensuring it doesn't go below zero
      new_amount = [ payment.amount_cents + adjustment, 0 ].max

      ActiveRecord::Base.transaction do
        payment.update!(amount_cents: new_amount)

        # Update associated cashier transaction
        if (cashier_transaction = payment.cashier_transaction)
          cashier_transaction.update!(amount_cents: new_amount)

          # If this is a bank payment method, update the bank cashier transaction too
          if payment.payment_method.payment_method_type == "bank"
            bank_cashier_transaction = CashierTransaction.find_by(
              transactable: payment,
              cashier_shift: CashierShift.joins(:cashier)
                                       .where(cashiers: { name: payment.payment_method.description })
                                       .where(status: :open)
                                       .first
            )
            bank_cashier_transaction&.update!(amount_cents: new_amount)
          end
        end
      end
    end
  end

  def adjust_commissions_proportionally(difference_cents)
    commissions = @order.commissions
    total_commission_sale_amount = commissions.sum(:sale_amount_cents)

    commissions.each do |commission|
      # Calculate the proportion this commission represents of the total
      commission_ratio = commission.sale_amount_cents.to_f / total_commission_sale_amount

      # Calculate this commission's share of the difference
      sale_amount_adjustment = (difference_cents * commission_ratio).round

      # Calculate new amounts ensuring they don't go below zero
      new_sale_amount = [ commission.sale_amount_cents + sale_amount_adjustment, 0 ].max
      new_commission_amount = (new_sale_amount * commission.percentage / 100.0).round

      commission.update!(
        sale_amount_cents: new_sale_amount,
        amount_cents: new_commission_amount
      )
    end
  end

  def update_warehouse_inventory(product_id, original_qty, new_qty)
    warehouse = @order.location.warehouses.first
    inventory = warehouse.warehouse_inventories.find_by(product_id: product_id)

    quantity_difference = original_qty - new_qty
    new_stock = inventory.stock + quantity_difference

    inventory.update!(stock: new_stock)
  end
end
