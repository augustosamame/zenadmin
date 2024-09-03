class CommissionPayout < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  belongs_to :commission
  belongs_to :user

  monetize :amount_cents, with_model_currency: :currency

  enum :status, { pending: 0, completed: 1 }
  translate_enum :status

  validates :amount_cents, presence: true

  # Callback to mark commission as paid_out when payout is completed
  after_commit :mark_commission_as_paid_out, if: :completed?

  private

  def mark_commission_as_paid_out
    commission.update(status: :paid_out)
  end
end
