module Services
  module Inventory
    class OrderItemService
      def initialize(order)
        @order = order
      end

      def update_inventory_or_create_pending_transfer
        if @order.fast_stock_transfer_flag
          # For orders with fast_stock_transfer_flag = true, update inventory immediately
          update_warehouse_inventory
        else
          # For orders with fast_stock_transfer_flag = false, create a pending stock transfer
          create_pending_stock_transfer
        end
      end

      def update_warehouse_inventory
        warehouse = @order.location.warehouses.first
        @order.order_items.each do |order_item|
          product_to_update = warehouse.warehouse_inventories.find_by(product_id: order_item.product_id)
          if product_to_update.present?
            product_to_update.update(stock: product_to_update.stock - order_item.quantity)
          else
            product_to_update = WarehouseInventory.create(warehouse: warehouse, product: order_item.product, stock: -order_item.quantity)
          end
          if product_to_update.stock < 0
            Preorder.create(warehouse: warehouse, product: order_item.product, order: @order, quantity: product_to_update.stock.abs)
          end
        end
      end

      def create_pending_stock_transfer
        origin_warehouse = @order.location.warehouses.first
        return unless origin_warehouse.present?

        # Create a new stock transfer to the client
        stock_transfer = StockTransfer.new(
          user_id: @order.user_id,
          origin_warehouse_id: origin_warehouse.id,
          destination_warehouse_id: nil, # No destination warehouse for client transfers
          customer_user_id: @order.user_id, # Set the customer as the destination
          to_customer: "1", # This is required for validation to pass
          transfer_date: Time.zone.now,
          comments: "Creado automáticamente desde la orden #{@order.custom_id}"
        )

        # Add lines for each product in the order
        @order.order_items.each do |item|
          next if item.product.nil? || item.quantity <= 0

          stock_transfer.stock_transfer_lines.build(
            product_id: item.product_id,
            quantity: item.quantity
          )
        end

        # Save the stock transfer (it will be in pending stage by default)
        unless stock_transfer.save
          Rails.logger.error "Failed to create StockTransfer from Order #{@order.id}: #{stock_transfer.errors.full_messages.join(", ")}"
        end
      end
    end
  end
end
