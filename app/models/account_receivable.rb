class AccountReceivable < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  belongs_to :user
  belongs_to :order, optional: true
  belongs_to :payment, optional: true # Original credit payment
  has_one :location, through: :order
  has_many :account_receivable_payments, dependent: :destroy
  has_many :payments, through: :account_receivable_payments  # Actual payments made

  monetize :amount_cents, with_model_currency: :currency

  enum :status, { pending: 0, partially_paid: 1, paid: 2, cancelled: 3, overdue: 4 }
  translate_enum :status

  validates :amount_cents, :currency, presence: true

  after_create :set_due_date

  def remaining_balance
    (amount_cents - payments.sum(:amount_cents)) / 100.0
  end

  def description
    self[:description] || "Cuenta por cobrar"
  end

  private

  def set_due_date
    # Set due date to 30 days from creation by default
    default_days = $global_settings[:default_credit_receivable_due_date] || 30
    self.update_column(:due_date, created_at + default_days.days) unless due_date
  end
end
