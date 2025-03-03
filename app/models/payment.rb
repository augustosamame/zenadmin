class Payment < ApplicationRecord
  audited_if_enabled
  include PgSearch::Model
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
  belongs_to :original_payment, class_name: "Payment", optional: true
  belongs_to :account_receivable, optional: true
  has_many :derived_payments, class_name: "Payment", foreign_key: "original_payment_id", dependent: :nullify
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

  after_create :create_cashier_transaction

  scope :for_location, ->(location) { joins(cashier_shift: :cashier).where(cashiers: { location_id: location.id }) }
  scope :unapplied, -> { where(account_receivable_id: nil, status: :paid) }

  pg_search_scope :search_by_all_fields,
    against: [ :custom_id, :amount_cents, :processor_transacion_id ],
    associated_against: {
      user: [ :first_name, :last_name ]
    },
    using: {
      tsearch: {
        prefix: true,
        any_word: true,
        dictionary: "spanish"
      }
    }

  def order
    payable if payable_type == "Order"
  end

  def set_payment_date
    self.payment_date = Time.zone.now if self.payment_date.nil?
  end

  def description
    return self[:description] if self[:description].present?

    payable_name = case payable_type&.underscore
    when "order"
      "Venta #{payable&.custom_id}"
    when nil
      "Saldo inicial a favor"
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
