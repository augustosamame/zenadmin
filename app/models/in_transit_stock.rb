class InTransitStock < ApplicationRecord
  belongs_to :user
  belongs_to :stock_transfer
  belongs_to :product
  belongs_to :origin_warehouse, class_name: "Warehouse"
  belongs_to :destination_warehouse, class_name: "Warehouse"
end
