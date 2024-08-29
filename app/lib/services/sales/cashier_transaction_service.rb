module Services
  module Sales
    class CashierTransactionService
      def initialize(cashier_shift)
        @cashier_shift = cashier_shift
      end

      # payment does not need a method to add a payment, it is already done in the payment service

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

      def open_shift(opened_by_user)
        ActiveRecord::Base.transaction do
          last_closed_shift = @cashier_shift.cashier.cashier_shifts.where(status: :closed).order(id: :desc).first

          if last_closed_shift
            last_closed_shift.cashier_transactions.includes(:payment_method).group_by(&:payment_method).each do |payment_method, transactions|
              total_amount_cents = transactions.sum(&:amount_cents)
              CashierTransaction.create!(
                cashier_shift: @cashier_shift,
                amount_cents: total_amount_cents,
                payment_method: payment_method,
                transactable: CashInflow.new(
                  cashier_shift: @cashier_shift, # Ensure the cashier_shift is set
                  amount_cents: total_amount_cents,
                  received_by: opened_by_user,
                  description: "Saldo de caja anterior - #{payment_method&.description || 'Sin método de pago'}"
                )
              )
            end
          end
        end
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

          { success: true }
        end
      rescue => e
        Rails.logger.error("Failed to close cashier shift: #{e.message}")
        { success: false, error: "Error al cerrar el turno de caja: #{e.message}" }
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
