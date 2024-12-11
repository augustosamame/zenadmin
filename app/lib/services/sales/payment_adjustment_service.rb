class Services::Sales::PaymentAdjustmentService
  def initialize(order)
    @order = order
  end

  def adjust_payments
    Rails.logger.info("Adjusting payments for order #{@order.id}")
    return unless @order.payments.any?

    total_payments_cents = @order.payments.sum(:amount_cents)
    difference_cents = @order.total_price_cents - total_payments_cents

    return if difference_cents.zero?

    # If the difference is tiny (1-2 cents), add it to the largest payment
    if difference_cents.abs <= 2
      largest_payment = @order.payments.order(amount_cents: :desc).first
      new_amount_cents = largest_payment.amount_cents + difference_cents

      ActiveRecord::Base.transaction do
        largest_payment.update!(amount_cents: new_amount_cents)
        @order.update!(payment_status: "paid") if @order.payment_status == "partially_paid"

        # Update associated cashier transaction if exists
        if (cashier_transaction = largest_payment.cashier_transaction)
          cashier_transaction.update!(amount_cents: new_amount_cents)

          # Handle bank payment methods
          if largest_payment.payment_method.payment_method_type == "bank"
            bank_cashier_transaction = CashierTransaction.find_by(
              transactable: largest_payment,
              cashier_shift: CashierShift.joins(:cashier)
                                     .where(cashiers: { name: largest_payment.payment_method.description })
                                     .where(status: :open)
                                     .first
            )
            bank_cashier_transaction&.update!(amount_cents: new_amount_cents)
          end
        end
      end
    end
  end
end
