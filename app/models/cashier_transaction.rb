class CashierTransaction < ApplicationRecord
  belongs_to :cashier_shift
  has_one :cashier, through: :cashier_shift
  belongs_to :transactable, polymorphic: true
  belongs_to :payment_method

  accepts_nested_attributes_for :transactable, allow_destroy: true

  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }

  monetize :amount_cents, with_model_currency: :currency

  # Fix for incorrect namespace reference
  def transactable_type=(class_name)
    # Convert "Purchases::PurchaseInvoice" to "PurchaseInvoice" if needed
    normalized_class_name = class_name == "Purchases::PurchaseInvoice" ? "PurchaseInvoice" : class_name
    super(normalized_class_name)
  end

  def amount_for_balance
    case transactable_type
    when "CashInflow"
      amount_cents
    when "CashOutflow", "PurchasePayment"
      -amount_cents
    else
      amount_cents # For payments and other types, assume positive
    end
  end
end
