class CashierShift < ApplicationRecord
  include TranslateEnum

  belongs_to :cashier
  belongs_to :opened_by, class_name: "User"
  belongs_to :closed_by, class_name: "User", optional: true

  has_many :cashier_transactions, dependent: :restrict_with_error
  has_many :payments, through: :cashier_transactions, source: :transactable, source_type: "Payment"
  has_many :cash_inflows, through: :cashier_transactions, source: :transactable, source_type: "CashInflow"
  has_many :cash_outflows, through: :cashier_transactions, source: :transactable, source_type: "CashOutflow"

  enum :status, { open: 0, closed: 1 }
  translate_enum :status

  validates :date, presence: true
  validates :status, presence: true
  validates :total_sales_cents, numericality: { greater_than_or_equal_to: 0 }

  before_create :check_if_shift_is_open

  def check_if_shift_is_open
    if cashier.cashier_shifts.open.exists?
      errors.add(:base, "Ya hay un turno de caja abierto para este cajero: #{cashier.name}.")
      throw(:abort)
    end
  end

  def total_balance
    total_payments = Money.new(payments.sum(:amount_cents), "PEN")
    total_inflows = Money.new(cash_inflows.sum(:amount_cents), "PEN")
    total_outflows = Money.new(cash_outflows.sum(:amount_cents), "PEN")

    total_payments + total_inflows - total_outflows
  end
end
