class Purchases::PurchaseOrderLine < ApplicationRecord
  belongs_to :purchase_order, class_name: "Purchases::PurchaseOrder"
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  monetize :unit_price_cents

  def total_price
    unit_price * quantity
  end
end
