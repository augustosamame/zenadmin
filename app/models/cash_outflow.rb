class CashOutflow < ApplicationRecord
  include CustomNumberable
  
  belongs_to :cashier_shift
  belongs_to :paid_to, class_name: "User" # User who received the cash outflow
  has_one :cashier_transaction, as: :transactable, dependent: :destroy
  has_many :media, as: :attachable, dependent: :destroy

  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :paid_to, presence: true
end
