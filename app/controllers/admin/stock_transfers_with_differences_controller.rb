class Admin::StockTransfersWithDifferencesController < Admin::AdminController
  def index
    @stock_transfer_lines = StockTransferLine.joins(:stock_transfer, :product)
      .joins("JOIN warehouses AS origin_warehouses ON stock_transfers.origin_warehouse_id = origin_warehouses.id")
      .joins("JOIN warehouses AS destination_warehouses ON stock_transfers.destination_warehouse_id = destination_warehouses.id")
      .select(
        "stock_transfer_lines.id",
        "stock_transfer_lines.quantity",
        "stock_transfer_lines.received_quantity",
        "stock_transfers.custom_id",
        "stock_transfers.created_at",
        "origin_warehouses.name as origin_warehouse_name",
        "destination_warehouses.name as destination_warehouse_name",
        "products.name as product_name"
      )
      .where("stock_transfer_lines.quantity != stock_transfer_lines.received_quantity")
      .order("stock_transfers.created_at DESC")

    respond_to do |format|
      format.html
    end
  end

  def accept_origin_quantity
    stock_transfer_line = StockTransferLine.find(params[:id])
    new_received_quantity = stock_transfer_line.quantity

    if stock_transfer_line.update_column(:received_quantity, new_received_quantity)
      destination_warehouse_inventory = WarehouseInventory.find_by(warehouse: stock_transfer_line.stock_transfer.destination_warehouse, product: stock_transfer_line.product)
      WarehouseInventory.reconstruct_single_inventory_stock(destination_warehouse_inventory)
      flash[:notice] = "Cantidad de origen aceptada exitosamente."
    else
      flash[:alert] = "Error al actualizar la cantidad: #{stock_transfer_line.errors.full_messages.join(', ')}"
    end

    redirect_to admin_stock_transfers_with_differences_path
  end

  def accept_destination_quantity
    stock_transfer_line = StockTransferLine.find(params[:id])
    new_quantity = stock_transfer_line.received_quantity

    if stock_transfer_line.update_column(:quantity, new_quantity)
      origin_warehouse_inventory = WarehouseInventory.find_by(warehouse: stock_transfer_line.stock_transfer.origin_warehouse, product: stock_transfer_line.product)
      WarehouseInventory.reconstruct_single_inventory_stock(origin_warehouse_inventory)

      flash[:notice] = "Cantidad de destino aceptada exitosamente."
    else
      flash[:alert] = "Error al actualizar la cantidad: #{stock_transfer_line.errors.full_messages.join(', ')}"
    end

    redirect_to admin_stock_transfers_with_differences_path
  end
end
