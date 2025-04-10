module Services
  module Sales
    class OrderPaymentEditService
      def self.update_payments(order, payments_attributes, current_cashier, current_cashier_shift, current_user)
        ActiveRecord::Base.transaction do
          payments_attributes.each do |_, payment_attrs|
            if payment_attrs[:id].present?
              # Update existing payment
              payment = order.payments.find(payment_attrs[:id])
              if payment_attrs[:_destroy] == "1"
                payment.destroy
              else
                amount_cents = (payment_attrs[:amount].to_f * 100).to_i
                payment.update!(
                  amount_cents: amount_cents,
                  payment_method_id: payment_attrs[:payment_method_id]
                )

                # Update associated cashier transaction if exists
                if (transaction = payment.cashier_transaction)
                  transaction.update!(
                    amount_cents: amount_cents,
                    payment_method_id: payment_attrs[:payment_method_id]
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
                      amount_cents: amount_cents,
                      payment_method_id: payment_attrs[:payment_method_id]
                    )
                  end
                end
              end
            else
              # Create new payment
              next if payment_attrs[:_destroy] == "1"

              amount_cents = (payment_attrs[:amount].to_f * 100).to_i
              payment = order.payments.create!(
                payment_method_id: payment_attrs[:payment_method_id],
                amount_cents: amount_cents,
                user_id: order.user_id,
                currency: order.currency || "PEN",
                cashier_shift: order.determine_cashier_shift_based_on_order_date(current_cashier, current_cashier_shift, current_user)
              )

              # Handle bank cashier transaction for new payments
              if payment.payment_method.payment_method_type == "bank"
                bank_cashier_shift = CashierShift.joins(:cashier)
                  .where(cashiers: { name: payment.payment_method.description })
                  .where(status: :open)
                  .first

                if bank_cashier_shift
                  CashierTransaction.create!(
                    transactable: payment,
                    cashier_shift: bank_cashier_shift,
                    amount_cents: amount_cents,
                    payment_method_id: payment_attrs[:payment_method_id]
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end
