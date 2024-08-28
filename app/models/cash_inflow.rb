class CashInflow < ApplicationRecord
  belongs_to :cashier_shift
  belongs_to :received_by, class_name: 'User' # User who receives the cash
  has_one :cashier_transaction, as: :transactable, dependent: :destroy
  has_one :media, as: :attachable, dependent: :destroy

  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :received_by, presence: true

  after_create :create_cashier_transaction

  private

  def create_cashier_transaction
    CashierTransaction.create!(
      cashier_shift: cashier_shift,
      transactable: self,
      transaction_type: :cash_inflow,
      amount_cents: amount_cents
    )
  end
end