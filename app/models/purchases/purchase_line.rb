class Purchases::PurchaseLine < ApplicationRecord
  belongs_to :purchase, class_name: "Purchases::Purchase"
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  monetize :unit_price_cents

  # You can access the supplier through the product:
  delegate :sourceable, to: :product, prefix: true

  def total_price
    unit_price * quantity
  end
end
