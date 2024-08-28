class CashierTransaction < ApplicationRecord
  belongs_to :cashier_shift
  belongs_to :transactable, polymorphic: true
  belongs_to :payment_method

  accepts_nested_attributes_for :transactable, allow_destroy: true

  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }

  monetize :amount_cents, with_model_currency: :currency

  def amount_for_balance
    case transactable_type
    when 'CashInflow'
      amount_cents
    when 'CashOutflow'
      -amount_cents
    else
      amount_cents # For payments and other types, assume positive
    end
  end

end