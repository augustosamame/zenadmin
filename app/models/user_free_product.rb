class UserFreeProduct < ApplicationRecord
  belongs_to :user
  belongs_to :product
  belongs_to :loyalty_tier

  enum status: { available: 0, claimed: 1 }

  scope :available, -> { where(status: :available) }
  scope :claimed, -> { where(status: :claimed) }
end
