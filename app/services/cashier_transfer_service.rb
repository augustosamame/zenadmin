class CashierTransferService
  def self.process_cashier_transfer(cash_outflow, target_cashier_id = nil)
    # Use the provided target_cashier_id or try to get it from the cash_outflow
    paid_to_id = target_cashier_id || cash_outflow.paid_to_id
    return unless paid_to_id.to_s.start_with?("cashier_")

    # Extract the target cashier ID from the paid_to_id
    target_cashier_id = paid_to_id.to_s.gsub("cashier_", "").to_i
    target_cashier = Cashier.find_by(id: target_cashier_id)

    return unless target_cashier

    # Get the current open shift for the target cashier
    target_shift = target_cashier.cashier_shifts.find_by(status: :open)

    # If no open shift exists, create one
    unless target_shift
      target_shift = target_cashier.cashier_shifts.create!(
        date: Date.current,
        opened_at: Time.current,
        opened_by_id: cash_outflow.cashier_shift.opened_by_id, # Use the same user who opened the source shift
        status: :open,
        total_sales_cents: 0
      )
    end

    # Create a CashInflow for the target cashier
    ActiveRecord::Base.transaction do
      cash_inflow = CashInflow.new(
        cashier_shift: target_shift,
        amount_cents: cash_outflow.amount_cents,
        currency: cash_outflow.currency,
        received_by_id: cash_outflow.cashier_shift.opened_by_id, # Use the same user who opened the source shift
        description: "Transferencia desde #{cash_outflow.cashier_shift.cashier.name} - #{cash_outflow.description}",
        processor_transacion_id: cash_outflow.processor_transacion_id
      )

      # Create the cashier transaction for the inflow
      cashier_transaction = CashierTransaction.new(
        cashier_shift: target_shift,
        transactable: cash_inflow,
        amount_cents: cash_outflow.amount_cents,
        currency: cash_outflow.currency,
        payment_method_id: cash_outflow.cashier_transaction.payment_method_id,
        processor_transacion_id: cash_outflow.processor_transacion_id
      )

      # Save both records
      cash_inflow.save!
      cashier_transaction.save!

      # Return the created inflow
      cash_inflow
    end
  rescue => e
    Rails.logger.error("Error processing cashier transfer: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    nil
  end
end
