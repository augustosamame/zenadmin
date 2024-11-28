class WarehouseInventory < ApplicationRecord
  audited_if_enabled

  belongs_to :warehouse
  belongs_to :product

  validate :stock_numericality_based_on_settings
  validates :warehouse_id, uniqueness: { scope: :product_id, message: "should have a unique product stock record" }

  def self.reconstruct_stock_from_movements(warehouse_id, dry_run = false)
    warehouse = Warehouse.find(warehouse_id)
    warehouse_inventory_records = WarehouseInventory.where(warehouse: warehouse)
    warehouse_inventory_records.each do |warehouse_inventory|
      initial_stock = 0
      incoming_stock_transfer_lines = StockTransferLine.joins(:stock_transfer).where(product: warehouse_inventory.product, stock_transfer: { destination_warehouse: warehouse })
      incoming_stock_transfer_lines.each do |stock_transfer_line|
        initial_stock += stock_transfer_line.quantity
      end

      outgoing_stock_transfer_lines = StockTransferLine.joins(:stock_transfer).where(product: warehouse_inventory.product, stock_transfer: { origin_warehouse: warehouse })
      outgoing_stock_transfer_lines.each do |stock_transfer_line|
        initial_stock -= stock_transfer_line.quantity
      end

      product_order_items = OrderItem.joins(:order).where(product: warehouse_inventory.product, order: { location_id: warehouse.location_id })
      product_order_items.each do |order_item|
        initial_stock -= order_item.quantity
      end

      current_stock = warehouse_inventory.stock

      if dry_run
        Rails.logger.info("Would have reconstructed stock for product #{warehouse_inventory.product.name} in warehouse #{warehouse.name}: #{initial_stock} (previous stock: #{current_stock})")
      else
        Rails.logger.info("Reconstructed stock for product #{warehouse_inventory.product.name} in warehouse #{warehouse.name}: #{initial_stock} (previous stock: #{current_stock})")
        warehouse_inventory.update!(stock: initial_stock)
      end
    end
  end

  private

    def stock_numericality_based_on_settings
      unless $global_settings[:negative_stocks_allowed]
        errors.add(:stock, "El stock resultante debe ser igual o mayor que 0") if stock < 0
      end
    end
end
