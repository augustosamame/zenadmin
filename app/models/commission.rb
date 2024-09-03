class Commission < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  belongs_to :user
  belongs_to :order
  has_one :commission_payout, dependent: :destroy

  enum :status, { status_order_unpaid: 0, status_order_paid: 1, status_paid_out: 2 }
  translate_enum :status

  monetize :sale_amount_cents, with_model_currency: :currency
  monetize :amount_cents, with_model_currency: :currency

  validates :percentage, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :amount_cents, presence: true
  validates :sale_amount_cents, presence: true

  def ready_for_payout?
    order_paid?
  end
end
