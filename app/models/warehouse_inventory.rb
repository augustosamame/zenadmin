class WarehouseInventory < ApplicationRecord
  audited_if_enabled

  belongs_to :warehouse
  belongs_to :product

  validate :stock_numericality_based_on_settings
  validates :warehouse_id, uniqueness: { scope: :product_id, message: "should have a unique product stock record" }

  def self.reconstruct_stock_from_movements_all_warehouses(max_datetime = nil, only_get_value = false)
    Warehouse.all.each do |warehouse|
      WarehouseInventory.reconstruct_stock_from_movements(warehouse.id, max_datetime, only_get_value)
    end
  end

  def self.reconstruct_stock_from_movements(warehouse_id, max_datetime = nil, only_get_value = false)
    warehouse = Warehouse.find(warehouse_id)
    warehouse_inventory_records = WarehouseInventory.where(warehouse: warehouse)
    warehouse_inventory_records.each do |warehouse_inventory|
      reconstruct_single_inventory_stock(warehouse_inventory, max_datetime, only_get_value)
    end
  end

  def self.reconstruct_single_inventory_stock(warehouse_inventory, max_datetime = nil, only_get_value = false)
    initial_stock = 0
    warehouse = warehouse_inventory.warehouse

    incoming_stock_transfer_lines = StockTransferLine.joins(:stock_transfer)
      .where(product: warehouse_inventory.product, stock_transfer: { destination_warehouse: warehouse, is_adjustment: false })
    incoming_stock_transfer_lines = incoming_stock_transfer_lines.where("stock_transfer.transfer_date <= ?", max_datetime) if max_datetime
    incoming_stock_transfer_lines.each do |stock_transfer_line|
      initial_stock += stock_transfer_line.quantity
    end

    outgoing_stock_transfer_lines = StockTransferLine.joins(:stock_transfer)
      .where(product: warehouse_inventory.product, stock_transfer: { origin_warehouse: warehouse })
    outgoing_stock_transfer_lines = outgoing_stock_transfer_lines.where("stock_transfer.transfer_date <= ?", max_datetime) if max_datetime
    outgoing_stock_transfer_lines.each do |stock_transfer_line|
      if stock_transfer_line.stock_transfer.is_adjustment?
        initial_stock += stock_transfer_line.quantity
      else
        initial_stock -= stock_transfer_line.quantity
      end
    end

    product_order_items = OrderItem.joins(:order)
      .where(product: warehouse_inventory.product, order: { location_id: warehouse.location_id })
    product_order_items = product_order_items.where("order_items.created_at <= ?", max_datetime) if max_datetime
    product_order_items.each do |order_item|
      initial_stock -= order_item.quantity
    end

    current_stock = warehouse_inventory.stock

    if only_get_value
      initial_stock
    else
      Rails.logger.info("Reconstructed stock for product #{warehouse_inventory.product.name} in warehouse #{warehouse.name}: #{initial_stock} (previous stock: #{current_stock})")
      warehouse_inventory.update!(stock: initial_stock)
    end
  end

  def self.fix_all_inventory_adjustment_fields_based_on_stock(warehouse_id)
    warehouse = Warehouse.find(warehouse_id)
    warehouse_inventory_records = WarehouseInventory.where(warehouse: warehouse)

    warehouse_inventory_records.each do |warehouse_inventory|
      last_inventory = PeriodicInventory.where(warehouse: warehouse).order(:created_at).last
      last_inventory_adjustment_for_product = StockTransferLine.joins(:stock_transfer).where(stock_transfer: { is_adjustment: true, periodic_inventory_id: last_inventory&.id }, product_id: warehouse_inventory.product_id).order(:created_at).last
      last_inventory_line_for_product = last_inventory.periodic_inventory_lines.where(product_id: warehouse_inventory.product_id).order(:created_at).last
      if last_inventory_line_for_product && last_inventory_adjustment_for_product
        max_datetime_to_calculate_previous_stock = last_inventory_adjustment_for_product&.created_at - 1.second
        previous_stock = WarehouseInventory.reconstruct_single_inventory_stock(warehouse_inventory, max_datetime_to_calculate_previous_stock, true)
        if previous_stock
          last_inventory_line_for_product.update!(stock: previous_stock)
        end
        new_adjustment = last_inventory_line_for_product.real_stock - last_inventory_line_for_product.stock
        last_inventory_adjustment_for_product.update!(quantity: new_adjustment, received_quantity: new_adjustment)
        WarehouseInventory.reconstruct_single_inventory_stock(warehouse_inventory, nil, false)
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
