class CashierTransaction < ApplicationRecord
  belongs_to :cashier_shift
  belongs_to :transactable, polymorphic: true

  enum :transaction_type, { payment: 0, cash_inflow: 1, cash_outflow: 2 }

  validates :transaction_type, presence: true
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }

  # Calculate the total impact of a transaction on the cashier's balance
  def amount_for_balance
    case transaction_type
    when 'cash_inflow'
      amount_cents
    when 'cash_outflow'
      -amount_cents
    else
      amount_cents # For payments and other types, assume positive
    end
  end
end