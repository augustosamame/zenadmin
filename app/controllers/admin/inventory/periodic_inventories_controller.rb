class Admin::Inventory::PeriodicInventoriesController < Admin::AdminController
  def index
    @warehouse = @current_warehouse
    @periodic_inventories = PeriodicInventory.all.includes(:warehouse, :user).order(id: :desc)
    @datatable_options = "server_side:false;resource_name:'PeriodicInventory';sort_0_desc;"
  end

  def show
    @warehouse = @current_warehouse
    @periodic_inventory = PeriodicInventory.find(params[:id])
    @datatable_options = "server_side:false;resource_name:'PeriodicInventory';sort_0_asc;"
  end

  def new
    if params[:warehouse_id].present?
      @warehouse = Warehouse.find(params[:warehouse_id])
    else
      @warehouse = @current_warehouse
    end

    @products = Product
    .includes(:media, :warehouse_inventories)
    .left_joins(:warehouse_inventories) # Ensures products without inventory are included
    .where("warehouse_inventories.warehouse_id = ? OR warehouse_inventories.warehouse_id IS NULL", @warehouse.id)
    .select("products.*, COALESCE(warehouse_inventories.stock, 0) AS stock").order(id: :desc) # Use SQL to fetch stock in one go

    @datatable_options = "server_side:false;resource_name:'StockTransfer';sort_7_asc;no_buttons;create_button:false;"
  end

  def create
    differences = params[:differences]
    results = params[:results]
    responsible_user = User.find(params[:responsible_user_id])

    stock_transfers = []
    # main_warehouse_id = Warehouse.find_by!(is_main: true).id

    differences.each do |difference|
      stock_adjustment = difference[:stock_qty] - difference[:actual_qty]
      if stock_adjustment > 0 # missing stock
        stock_transfer = StockTransfer.create!(
          user_id: responsible_user.id,
          comments: "Ajuste de inventario",
          is_adjustment: true,
          adjustment_type: difference[:adjustment_type],
          stage: :pending,
          status: :active,
          transfer_date: Time.current,
          origin_warehouse_id: difference[:warehouse_id],
          # destination_warehouse_id: main_warehouse_id,
          stock_transfer_lines_attributes: [
            {
              product_id: difference[:product_id],
              quantity: stock_adjustment.abs
            }
          ]
        )

        stock_to_adjust = @current_warehouse.warehouse_inventories.find_by(product_id: difference[:product_id])
        stock_to_adjust.update(stock: stock_to_adjust.stock - stock_adjustment)

        stock_transfers << stock_transfer
      else
        # extra stock
        stock_transfer = StockTransfer.create!(
          user_id: responsible_user.id,
          comments: "Ajuste de inventario",
          is_adjustment: true,
          adjustment_type: difference[:adjustment_type],
          stage: :pending,
          status: :active,
          transfer_date: Time.current,
          origin_warehouse_id: difference[:warehouse_id],
          # destination_warehouse_id: difference[:warehouse_id],
          stock_transfer_lines_attributes: [
            {
              product_id: difference[:product_id],
              quantity: -(stock_adjustment.abs)
            }
          ]
        )

        stock_to_adjust = @current_warehouse.warehouse_inventories.find_by(product_id: difference[:product_id])
        stock_to_adjust.update(stock: stock_to_adjust.stock + stock_adjustment)

        stock_transfers << stock_transfer
      end
    end

    periodic_inventory = Services::Inventory::PeriodicInventoryService.create_manual_snapshot(
      warehouse: @current_warehouse,
      user: responsible_user,
      stock_transfer_ids: stock_transfers.pluck(:id)
    )

    if results[:differences_count] == 0
      message = "No se encontraron diferencias en el inventario"
    else
      message = "Se han creado #{results[:differences_count]} ajustes de inventario por las diferencias encontradas"
      Services::Notifications::CreateNotificationService.new(periodic_inventory, custom_strategy: "MissingStockPeriodicInventory").create
    end

    render partial: "admin/inventory/periodic_inventories/stock_adjustments",
           locals: { stock_transfers: stock_transfers, message: message }
  end

  def print_inventory_list
    @products = Product
      .includes(:warehouse_inventories)
      .left_joins(:warehouse_inventories)
      .where("warehouse_inventories.warehouse_id = ? OR warehouse_inventories.warehouse_id IS NULL", @current_warehouse.id)
      .select("products.*, COALESCE(warehouse_inventories.stock, 0) AS stock")
      .order(:name)

    pdf_content = InventoryListReport.new(
      Time.current,
      @current_warehouse,
      @products
    ).render

    send_data pdf_content,
      filename: "hoja_inventario_#{Time.current.strftime('%Y_%m_%d')}.pdf",
      type: "application/pdf",
      disposition: "inline"
  end
end
