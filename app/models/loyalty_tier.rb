class LoyaltyTier < ApplicationRecord
  has_many :users
  has_many :user_free_products
  belongs_to :free_product, class_name: "Product"

  enum :status, [ :active, :inactive ]

  validates :name, presence: true, uniqueness: true
end
