class PurchasePayment < ApplicationRecord
  audited_if_enabled
  include PgSearch::Model
  include TranslateEnum

  include DefaultRegionable
  include CustomNumberable
  PAYABLE = [ :purchase ]

  belongs_to :payment_method
  belongs_to :user
  belongs_to :region
  belongs_to :payable, polymorphic: true, autosave: true, optional: true
  belongs_to :cashier_shift, optional: true
  belongs_to :original_payment, class_name: "PurchasePayment", optional: true
  belongs_to :purchase_invoice, optional: true
  belongs_to :vendor, class_name: "Purchases::Vendor", optional: true
  has_many :derived_payments, class_name: "PurchasePayment", foreign_key: "original_payment_id", dependent: :nullify
  has_one :cashier, through: :cashier_shift
  has_one :location, through: :cashier
  belongs_to :purchase, class_name: "Purchases::Purchase", optional: true
  has_one :cashier_transaction, as: :transactable, dependent: :destroy
  has_many :purchase_invoices, dependent: :nullify
  has_many :purchase_invoice_payments, dependent: :destroy

  enum :status, { pending: 0, paid: 1, partially_paid: 2, cancelled: 3 }
  translate_enum :status

  monetize :amount_cents, with_model_currency: :currency

  validates :payment_method_id, :user_id, :amount_cents, :payment_date, presence: true

  before_validation :set_payment_date

  after_create :create_cashier_transaction, if: -> { cashier_shift.present? }

  scope :for_location, ->(location) { joins(cashier_shift: :cashier).where(cashiers: { location_id: location.id }) }
  scope :unapplied, -> { where(purchase_invoice_id: nil, status: :paid) }

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

  def purchase
    payable if payable_type == "Purchases::Purchase"
  end

  def set_payment_date
    self.payment_date = Time.zone.now if self.payment_date.nil?
  end

  def description
    return self[:description] if self[:description].present?

    if payable.present?
      payable_name = case payable_type&.underscore
      when "purchases/purchase"
        "Compra #{payable&.custom_id}"
      when nil
        "Saldo inicial"
      else
        "#{payable_type.underscore.humanize} #{payable&.custom_id}"
      end
    elsif vendor.present?
      payable_name = "Proveedor #{vendor.name}"
    else
      payable_name = "Saldo inicial"
    end

    "Pago a #{payable_name}"
  end

  def payable_attributes=(attributes)
    if PAYABLE.include?(payable_type.underscore.split("/").last.to_sym)
      self.payable ||= self.payable_type.constantize.new
      self.payable.assign_attributes(attributes)
    end
  end

  def self.create_payment(payment_method, user, payable, amount_cents, currency, payment_date, comment)
    payment = PurchasePayment.new
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
      Services::Sales::CashierTransactionService.new(self.cashier_shift).create_cashier_transaction(self) unless original_payment_id.present?
    end
end
