module Services
  module Inventory
    class PeriodicInventoryService
      def initialize(periodic_inventory)
        @periodic_inventory = periodic_inventory
      end

      def self.create_snapshot(warehouse:, user:, inventory_type:, stock_transfer_ids: [], real_stocks: {})
        @periodic_inventory = PeriodicInventory.create!(
          warehouse: warehouse,
          user: user,
          snapshot_date: Time.current,
          inventory_type: inventory_type
        )

        # Create inventory lines for each product in the warehouse
        warehouse.warehouse_inventories.each do |inventory|
          @periodic_inventory.periodic_inventory_lines.create!(
            product: inventory.product,
            stock: inventory.stock,
            real_stock: real_stocks.fetch(inventory.product_id.to_s, inventory.stock)
          )
        end

        # Associate stock transfers with the periodic inventory, if provided
        unless stock_transfer_ids.empty?
          stock_transfers = StockTransfer.where(id: stock_transfer_ids)
          stock_transfers.update_all(periodic_inventory_id: @periodic_inventory.id)
        end

        @periodic_inventory
      end

      def self.create_automatic_snapshot(warehouse:, user:, stock_transfer_ids: [], real_stocks: {})
        create_snapshot(
          warehouse: warehouse,
          user: user,
          inventory_type: :automatic,
          stock_transfer_ids: stock_transfer_ids,
          real_stocks: real_stocks
        )
      end

      def self.create_manual_snapshot(warehouse:, user:, stock_transfer_ids: [], real_stocks: {})
        create_snapshot(
          warehouse: warehouse,
          user: user,
          inventory_type: :manual,
          stock_transfer_ids: stock_transfer_ids,
          real_stocks: real_stocks
        )
      end
    end
  end
end
