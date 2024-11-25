class Payment < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  include DefaultRegionable
  include CustomNumberable
  PAYABLE = [ :order ]

  belongs_to :payment_method
  belongs_to :user
  belongs_to :region
  # belongs_to :payable, polymorphic: true, autosave: true, required: true
  belongs_to :payable, polymorphic: true, autosave: true, optional: true
  belongs_to :cashier_shift
  has_one :cashier, through: :cashier_shift
  has_one :location, through: :cashier
  belongs_to :order, optional: true
  has_one :cashier_transaction, as: :transactable, dependent: :destroy
  has_many :account_receivables, dependent: :destroy
  has_many :account_receivable_payments, dependent: :destroy

  enum :status, { pending: 0, paid: 1, partially_paid: 2, cancelled: 3 }
  translate_enum :status

  monetize :amount_cents, with_model_currency: :currency

  # validates :payment_method_id, :user_id, :payable_id, :payable_type, :amount_cents, :payment_date, presence: true
  validates :payment_method_id, :user_id, :amount_cents, :payment_date, presence: true
  # validates :payable, presence: true

  before_validation :set_payment_date
  before_validation :set_cashier_shift

  after_create :create_cashier_transaction

  scope :for_location, ->(location) { joins(cashier_shift: :cashier).where(cashiers: { location_id: location.id }) }

  def order
    payable if payable_type == "Order"
  end

  def set_payment_date
    self.payment_date = Time.zone.now if self.payment_date.nil?
  end

  def set_cashier_shift
    self.cashier_shift = cashier_shift_id.present? ? cashier_shift : CashierShift.open&.last
  end

  def description
    payable_name = case payable_type.underscore
    when "order"
      "Venta #{payable&.custom_id}"
    else
      "#{payable_type.underscore.humanize} #{payable&.custom_id}"
    end

    "Pago de #{payable_name}"
  end

  def payable_attributes=(attributes)
    if PAYABLE.include?(payable_type.underscore.to_sym)
      self.payable ||= self.payable_type.constantize.new
      self.payable.assign_attributes(attributes)
    end
  end

  def self.create_payment(payment_method, user, payable, amount_cents, currency, payment_date, comment)
    payment = Payment.new
    payment.payment_method = payment_method
    payment.user = user
    payment.payable = payable
    payment.amount_cents = amount_cents
    payment.currency = currency
    payment.payment_date = payment_date
    payment.comment = comment
    payment.status = :pending
    payment.save
  end

  private

    def create_cashier_transaction
      Services::Sales::CashierTransactionService.new(self.cashier_shift).create_cashier_transaction(self)
    end
end
