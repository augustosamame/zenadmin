module Services
  module Inventory
    class StockTransferService
      attr_reader :stock_transfer

      def initialize(stock_transfer)
        @stock_transfer = stock_transfer
      end

      # Handles updating inventory when moving to 'in_transit'
      def update_origin_warehouse_inventory
        return if stock_transfer.origin_warehouse_id.nil? # Skip if no origin warehouse

        stock_transfer.stock_transfer_lines.each do |line|
          # Find or initialize the warehouse inventory record
          warehouse_inventory = WarehouseInventory.find_or_initialize_by(
            warehouse_id: stock_transfer.origin_warehouse_id,
            product_id: line.product_id
          )
          # check if there is enough stock in the origin warehouse
          if warehouse_inventory && (warehouse_inventory.stock >= line.quantity || $global_settings[:negative_stocks_allowed])
            # update the stock in the origin warehouse
            warehouse_inventory.update!(stock: warehouse_inventory.stock - line.quantity)
            # Create record only if moving to 'in_transit'
            create_in_transit_record(line) if stock_transfer.may_start_transfer?
          else
            raise "Insufficient stock in origin warehouse for product #{line.product_id}"
          end
        end
      end

      def update_adjustment_inventory
        stock_transfer.destination_warehouse_id = Warehouse.find_by(is_main: true).id
        stock_transfer.stock_transfer_lines.each do |line|
          if stock_transfer.destination_warehouse_id == stock_transfer.origin_warehouse_id && stock_transfer.destination_warehouse_id == Warehouse.find_by(is_main: true).id
            stock_transfer.update_column(:destination_warehouse_id, nil)
          end
          if stock_transfer.adjustment_type == "devolucion" && stock_transfer.destination_warehouse_id.present?
            destination_warehouse_inventory = WarehouseInventory.find_or_initialize_by(warehouse_id: stock_transfer.destination_warehouse_id, product_id: line.product_id)
            destination_warehouse_inventory.stock ||= 0
            destination_warehouse_inventory.stock -= line.quantity
            destination_warehouse_inventory.save!
          end
          warehouse_inventory = WarehouseInventory.find_or_initialize_by(warehouse_id: stock_transfer.origin_warehouse_id, product_id: line.product_id)
          warehouse_inventory.stock ||= 0
          warehouse_inventory.stock += line.quantity
          saved = warehouse_inventory.save!
        end
      end

      # Handles updating inventory when moving to 'complete'
      def update_destination_warehouse_inventory
        stock_transfer.stock_transfer_lines.each do |line|
          warehouse_inventory = WarehouseInventory.find_or_initialize_by(warehouse_id: stock_transfer.destination_warehouse_id, product_id: line.product_id)
          warehouse_inventory.stock ||= 0
          quantity_to_add = line.received_quantity || line.quantity
          warehouse_inventory.stock += quantity_to_add
          warehouse_inventory.save!
          if line.received_quantity != line.quantity
            Services::Notifications::CreateNotificationService.new(stock_transfer, custom_strategy: "PartialStockTransfer").create
          end
          remove_in_transit_record(line) if stock_transfer.aasm.from_state == :in_transit
        end
      end

      private

      def create_in_transit_record(line)
        InTransitStock.create!(
          user_id: stock_transfer.user_id,
          stock_transfer_id: stock_transfer.id,
          product_id: line.product_id,
          quantity: line.quantity,
          origin_warehouse_id: stock_transfer.origin_warehouse_id,
          destination_warehouse_id: stock_transfer.destination_warehouse_id
        )
      end

      def remove_in_transit_record(line)
        InTransitStock.where(stock_transfer_id: stock_transfer.id, product_id: line.product_id).destroy_all
      end
    end
  end
end
