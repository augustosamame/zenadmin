module Services
  module Sales
    class OrderPaymentEditService
      def initialize(order)
        @order = order
      end

      def update_payments(payments_params)
        # Validate total matches
        new_total = payments_params.values.sum { |p| p[:amount_cents] }
        return false unless new_total == @order.total_price_cents

        ActiveRecord::Base.transaction do
          payments_params.each do |id, payment_params|
            payment = @order.payments.find(id)

            # Update payment
            payment.update!(
              payment_method_id: payment_params[:payment_method_id],
              amount_cents: payment_params[:amount_cents]
            )

            # Update associated cashier transaction
            if (cashier_transaction = payment.cashier_transaction)
              cashier_transaction.update!(
                amount_cents: payment_params[:amount_cents],
                payment_method_id: payment_params[:payment_method_id]
              )

              # Update bank cashier transaction if needed
              if payment.payment_method.payment_method_type == "bank"
                bank_cashier_transaction = CashierTransaction.find_by(
                  transactable: payment,
                  cashier_shift: CashierShift.joins(:cashier)
                    .where(cashiers: { name: payment.payment_method.description })
                    .where(status: :open)
                    .first
                )
                bank_cashier_transaction&.update!(
                  amount_cents: payment_params[:amount_cents],
                  payment_method_id: payment_params[:payment_method_id]
                )
              end
            end
          end

          # Reevaluate payment status
          @order.reevaluate_payment_status
        end

        true
      rescue ActiveRecord::RecordInvalid
        false
      end
    end
  end
end
