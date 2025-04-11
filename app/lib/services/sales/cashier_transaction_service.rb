module Services
  module Sales
    class CashierTransactionService
      def initialize(cashier_shift)
        @cashier_shift = cashier_shift
      end

      # payment does not need a method to add a payment, it is already done in the payment service

      def create_cashier_transaction(payment)
        if $global_settings[:linked_cashiers_for_payment_methods]
          linked_cashier_id = payment.payment_method&.cashier_linked_id
          if linked_cashier_id
            @cashier_shift = CashierShift.where(cashier: Cashier.find(linked_cashier_id), status: :open).first
            if @cashier_shift.blank?
              @cashier_shift = CashierShift.create!(cashier: Cashier.find(linked_cashier_id), opened_by: User.with_role(:super_admin).first, total_sales_cents: 0, date: DateTime.current, opened_at: DateTime.current, status: :open)
            end
          end
        end
        CashierTransaction.create!(
          cashier_shift: @cashier_shift,
          transactable: payment,
          amount_cents: payment.amount_cents,
          currency: payment.currency,
          payment_method: payment.payment_method,
          processor_transacion_id: payment.processor_transacion_id,
          created_at: payment.payment_date
        )
        payment.update_columns(cashier_shift_id: @cashier_shift.id)
      end

      def add_cash_inflow(amount_cents, received_by, comment = nil)
        cash_inflow = CashInflow.create!(
          cashier_shift: @cashier_shift,
          amount_cents: amount_cents,
          received_by: received_by,
          comment: comment,
          processor_transacion_id: processor_transacion_id
        )
      end

      def add_cash_outflow(amount_cents, paid_to, comment = nil)
        cash_outflow = CashOutflow.create!(
          cashier_shift: @cashier_shift,
          amount_cents: amount_cents,
          paid_to: paid_to,
          comment: comment,
          processor_transacion_id: processor_transacion_id
        )
      end

      def open_shift(opened_by_user)
        ActiveRecord::Base.transaction do
          last_closed_shift = @cashier_shift.cashier.cashier_shifts.where(status: :closed).order(closed_at: :desc).first

          if last_closed_shift
            last_closed_shift.cashier_transactions.includes(:payment_method).group_by(&:payment_method).each do |payment_method, transactions|
              next if $global_settings[:only_pull_cash_value_from_previous_cashier_shift] && payment_method&.name != "cash"
              total_amount_cents = last_closed_shift.total_balance.cents
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
          { success: true }
        end
      rescue => e
        Rails.logger.error("Failed to close cashier shift: #{e.message}")
        { success: false, error: "Error al abrir un nuevo turno de caja" }
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
