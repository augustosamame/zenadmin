class WarehouseInventory < ApplicationRecord
  audited_if_enabled

  belongs_to :warehouse
  belongs_to :product

  validate :stock_numericality_based_on_settings
  validates :warehouse_id, uniqueness: { scope: :product_id, message: "should have a unique product stock record" }

  def self.reconstruct_stock_from_movements_all_warehouses(dry_run = false)
    Warehouse.all.each do |warehouse|
      WarehouseInventory.reconstruct_stock_from_movements(warehouse.id, dry_run)
    end
  end

  # TODO: add a method to reconstruct the stock from the stock transfers
  def self.reconstruct_stock_from_movements(warehouse_id, dry_run = false)
    warehouse = Warehouse.find(warehouse_id)
    warehouse_inventory_records = WarehouseInventory.where(warehouse: warehouse)
    warehouse_inventory_records.each do |warehouse_inventory|
      initial_stock = 0
      incoming_stock_transfer_lines = StockTransferLine.joins(:stock_transfer).where(product: warehouse_inventory.product, stock_transfer: { destination_warehouse: warehouse, is_ajustment: false })
      incoming_stock_transfer_lines.each do |stock_transfer_line|
        initial_stock += stock_transfer_line.quantity
      end

      outgoing_stock_transfer_lines = StockTransferLine.joins(:stock_transfer).where(product: warehouse_inventory.product, stock_transfer: { origin_warehouse: warehouse })
      outgoing_stock_transfer_lines.each do |stock_transfer_line|
        if stock_transfer_line.stock_transfer.is_ajustment
          initial_stock += stock_transfer_line.quantity
        else
          initial_stock -= stock_transfer_line.quantity
        end
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

  def self.create_records_for_all_products_in_main_warehouse
    main_warehouse = Warehouse.where(is_main: true).first
    Product.all.each do |product|
      warehouse_inventory_exists = WarehouseInventory.where(warehouse: main_warehouse, product: product).exists?
      unless warehouse_inventory_exists
        WarehouseInventory.create!(warehouse: main_warehouse, product: product, stock: 0)
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
