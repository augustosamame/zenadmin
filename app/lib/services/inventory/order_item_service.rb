module Services
  module Inventory
    class OrderItemService
      def initialize(order)
        @order = order
      end
   
      def update_inventory
        warehouse = @order.location.warehouses.first
        @order.order_items.each do |order_item|
          product_to_update = warehouse.warehouse_inventories.find_by(product_id: order_item.product_id)
          if product_to_update.present?
            product_to_update.update(stock: product_to_update.stock - order_item.quantity)
          else
            WarehouseInventory.create(warehouse: warehouse, product: order_item.product, stock: -order_item.quantity)
          end
        end
      end

      
    end
  end
end