class AccountReceivablePayment < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  belongs_to :account_receivable
  belongs_to :payment

  monetize :amount_cents, with_model_currency: :currency

  validates :amount_cents, :currency, presence: true

  after_commit :update_receivable_status

  enum :status, { pending: 0, paid: 1 }
  translate_enum :status

  private

  def update_receivable_status
    receivable = account_receivable
    total_paid = receivable.payments.sum(:amount_cents)

    if total_paid >= receivable.amount_cents
      receivable.update_column(:status, :paid)
    elsif total_paid > 0
      receivable.update_column(:status, :partially_paid)
    end
  end
end
