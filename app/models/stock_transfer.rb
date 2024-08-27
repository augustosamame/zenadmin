class StockTransfer < ApplicationRecord
  belongs_to :user
  belongs_to :origin_warehouse, class_name: "Warehouse", optional: true
  belongs_to :destination_warehouse, class_name: "Warehouse"
  has_many :stock_transfer_lines, dependent: :destroy
  has_many :products, through: :stock_transfer_lines

  enum :stage, { pending: 0, in_transit: 1, completed: 2 }
  enum :status, { active: 0, inactive: 1 }

  accepts_nested_attributes_for :stock_transfer_lines, allow_destroy: true

  validates :destination_warehouse, presence: true
  validate :different_warehouses

  def different_warehouses
    if origin_warehouse && origin_warehouse == destination_warehouse
      errors.add(:destination_warehouse, "el almacén de envío y destino no pueden ser el mismo")
    end
  end

  def total_products
    stock_transfer_lines.sum(:quantity)
  end
end
