module Services
  module Sales

    class CashierTransactionService
      def initialize(cashier_shift)
        @cashier_shift = cashier_shift
      end

      #payment does not need a method to add a payment, it is already done in the payment service

      def add_cash_inflow(amount_cents, received_by, comment = nil)
        cash_inflow = CashInflow.create!(
          cashier_shift: @cashier_shift,
          amount_cents: amount_cents,
          received_by: received_by,
          comment: comment
        )
      end

      def add_cash_outflow(amount_cents, paid_to, comment = nil)
        cash_outflow = CashOutflow.create!(
          cashier_shift: @cashier_shift,
          amount_cents: amount_cents,
          paid_to: paid_to,
          comment: comment
        )
      end

      def close_shift(closed_by_user)
        ActiveRecord::Base.transaction do
          total_balance = @cashier_shift.total_balance

          @cashier_shift.update!(
            total_sales_cents: total_balance,
            closed_at: Time.current,
            closed_by: closed_by_user,
            status: :closed
          )
        end
      rescue => e
        Rails.logger.error("Failed to close cashier shift: #{e.message}")
        raise
      end

      private

      def calculate_total_sales
        @cashier_shift.cashier_transactions.payment.sum(:amount_cents)
      end

      def calculate_total_balance
        # Calculate the total balance by summing all transactions' impact on balance
        @cashier_shift.cashier_transactions.sum(&:amount_for_balance)
      end

    end
    
  end
end