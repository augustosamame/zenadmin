class WarehouseInventory < ApplicationRecord
  belongs_to :warehouse
  belongs_to :product

  validates :stock, numericality: { greater_than_or_equal_to: 0 }
  validates :warehouse_id, uniqueness: { scope: :product_id, message: "should have a unique product stock record" }
end
