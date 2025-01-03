class Admin::Inventory::PeriodicInventoriesController < Admin::AdminController
  def index
    @warehouse = @current_warehouse
    @periodic_inventories = if current_user.any_admin_or_supervisor?
      PeriodicInventory.all
        .includes(:warehouse, :user)
        .order(id: :desc)
    else
      PeriodicInventory.where(warehouse: @current_warehouse)
        .includes(:warehouse, :user)
        .order(id: :desc)
    end
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

    # Create a hash of product_id => real_stock from differences
    real_stocks = differences.each_with_object({}) do |difference, hash|
      hash[difference[:product_id].to_s] = difference[:actual_qty]
    end

    stock_transfer = nil

    # Only create stock transfer if there are differences
    if differences.present?
      ActiveRecord::Base.transaction do
        # Create a single stock transfer for all adjustments
        stock_transfer = StockTransfer.create!(
          user_id: responsible_user.id,
          comments: "Ajuste de inventario",
          is_adjustment: true,
          adjustment_type: differences.first[:adjustment_type],
          stage: :pending,
          status: :active,
          transfer_date: Time.current,
          origin_warehouse_id: @current_warehouse.id
        )

        # Add all stock transfer lines
        differences.each do |difference|
          stock_adjustment = difference[:actual_qty] - difference[:stock_qty]
          next if stock_adjustment.zero?

          StockTransferLine.create!(
            stock_transfer: stock_transfer,
            product_id: difference[:product_id],
            quantity: stock_adjustment
          )
        end

        periodic_inventory = Services::Inventory::PeriodicInventoryService.create_manual_snapshot(
          warehouse: @current_warehouse,
          user: responsible_user,
          stock_transfer_ids: stock_transfer ? [ stock_transfer.id ] : [],
          real_stocks: real_stocks
        )

        if results[:differences_count] == 0
          message = "No se encontraron diferencias en el inventario"
        else
          message = "Se han creado #{results[:differences_count]} ajustes de inventario por las diferencias encontradas"
          Services::Notifications::CreateNotificationService.new(periodic_inventory, custom_strategy: "MissingStockPeriodicInventory").create
        end

        render partial: "admin/inventory/periodic_inventories/stock_adjustments",
               locals: { stock_transfers: stock_transfer ? [ stock_transfer ] : [], message: message }
      end
    end
  rescue StandardError => e
    Rails.logger.error "Error creating periodic inventory: #{e.message}"
    render json: { error: "Error al crear el inventario periódico: #{e.message}" }, status: :unprocessable_entity
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
