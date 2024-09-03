class Payment < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  include DefaultRegionable
  include CustomNumberable
  PAYABLE = [ :order ]

  belongs_to :payment_method
  belongs_to :user
  belongs_to :region
  belongs_to :payable, polymorphic: true, autosave: true, required: true
  belongs_to :cashier_shift
  has_one :cashier_transaction, as: :transactable, dependent: :destroy

  enum :status, { pending: 0, paid: 1, partially_paid: 2, cancelled: 3 }
  translate_enum :status

  monetize :amount_cents, with_model_currency: :currency

  validates :payment_method_id, :user_id, :payable_id, :payable_type, :amount_cents, :payment_date, presence: true
  validates :payable, presence: true

  before_validation :set_payment_date

  after_create :create_cashier_transaction

  def set_payment_date
    self.payment_date = Time.zone.now if self.payment_date.nil?
  end

  def description
    "Pago de #{payable_type.underscore.humanize} #{payable_id}"
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
      CashierTransaction.create!(
        cashier_shift: cashier_shift,
        transactable: self,
        amount_cents: amount_cents,
        payment_method: payment_method
      )
    end
end
