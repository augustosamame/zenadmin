# app/services/sales/credit_payment_service.rb
module Services
  module Sales
    class AccountReceivablePaymentService
      def initialize(account_receivable)
        @account_receivable = account_receivable
      end

      def process_payment(amount_cents:, payment_method:, cashier_shift:, user:)
        ActiveRecord::Base.transaction do
          # Create new payment
          payment = Payment.create!(
            payment_method: payment_method,
            user: user,
            payable: @account_receivable.order,
            amount_cents: amount_cents,
            currency: @account_receivable.currency,
            cashier_shift: cashier_shift,
            region: @account_receivable.order.region
          )

          # Link payment to account receivable
          AccountReceivablePayment.create!(
            account_receivable: @account_receivable,
            payment: payment,
            amount_cents: amount_cents,
            currency: @account_receivable.currency
          )

          # Update order payment status if needed
          Services::Sales::OrderCreditService.new(@account_receivable.order).reevaluate_payment_status
        end
      end
    end
  end
end
