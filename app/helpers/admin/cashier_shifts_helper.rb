module Admin::CashierShiftsHelper
  def payment_method_balances(cashier_shift)
    transactions_by_method = cashier_shift.cashier_transactions.includes(:payment_method).group_by(&:payment_method)

    balances = []

    transactions_by_method.each do |payment_method, transactions|
      # Use amount_for_balance to correctly account for transaction types
      total_cents = transactions.sum(&:amount_for_balance)
      total = Money.new(total_cents, "PEN")

      # Add regular balance
      balances << {
        description: payment_method&.description || "Sin método",
        amount: total
      }

      # For cash payments, add daily balance excluding previous shift
      if payment_method&.name == "cash"
        daily_cash = total - Money.new(cashier_shift.cash_from_previous_shift_cents, "PEN")
        balances << {
          description: "#{payment_method.description} del Día",
          amount: daily_cash
        }
      end
    end

    balances
  end
end
