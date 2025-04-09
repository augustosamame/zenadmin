class PurchaseInvoice < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  belongs_to :purchase, class_name: "Purchases::Purchase"
  belongs_to :vendor, class_name: "Purchases::Vendor", optional: true

  enum :purchase_invoice_type, {
    factura: 0,
    boleta: 1
  }
  translate_enum :purchase_invoice_type

  enum :payment_status, {
    pending: 0,
    partially_paid: 1,
    paid: 2,
    void: 3
  }
  translate_enum :payment_status

  validates :purchase_invoice_date, presence: true
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :custom_id, uniqueness: true, allow_blank: true

  monetize :amount_cents, with_model_currency: :currency

  before_validation :set_vendor_from_purchase

  private

  def set_vendor_from_purchase
    self.vendor_id = purchase.vendor_id if purchase.present? && vendor_id.blank?
  end
end
