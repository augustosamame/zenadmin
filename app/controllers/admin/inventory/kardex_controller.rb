class Admin::Inventory::KardexController < Admin::AdminController
  include ActionView::Helpers::NumberHelper

  def show
    if params[:product_id].present?
      @product = Product.find(params[:product_id])
    end
    if params[:warehouse_id].present?
      @warehouse = Warehouse.find(params[:warehouse_id])
    else
      @warehouse = @current_warehouse
    end

    # Automatically fetch kardex movements if both product_id and warehouse_id are present
    if params[:product_id].present? && (params[:warehouse_id].present? || @current_warehouse.present?)
      fetch_kardex_movements_for_show
    end
  end

  def fetch_kardex_movements
    product = Product.find(params[:product_id])
    selected_warehouse = params[:warehouse_id].present? ? Warehouse.find(params[:warehouse_id]) : @current_warehouse
    
    @movements = get_kardex_movements(product, selected_warehouse)

    # Respond with Turbo Stream or HTML
    respond_to do |format|
      format.turbo_stream
      # format.html { render partial: 'admin/inventorykardex/kardex_table', locals: { movements: @movements } }
    end
  end

  private

  def fetch_kardex_movements_for_show
    product = Product.find(params[:product_id])
    selected_warehouse = params[:warehouse_id].present? ? Warehouse.find(params[:warehouse_id]) : @current_warehouse
    
    @movements = get_kardex_movements(product, selected_warehouse)
  end

  def get_kardex_movements(product, selected_warehouse)
    # Fetch stock transfers and orders related to the product
    stock_transfers = product.stock_transfer_lines
                            .joins(:stock_transfer)
                            .includes(stock_transfer: [ :origin_warehouse, :destination_warehouse ])
                            .where("(stock_transfers.origin_warehouse_id = ? AND stock_transfers.stage IN (?)) OR (stock_transfers.destination_warehouse_id = ? AND stock_transfers.stage = ?)",
                                  selected_warehouse.id, [ "complete", "in_transit" ],
                                  selected_warehouse.id, "complete")
                            .order(:created_at)

    orders = OrderItem
      .joins(order: { location: :warehouses }) # Join order_items to orders, then to locations, then to warehouses
      .where(product_id: product.id, order: { fast_stock_transfer_flag: true }) # Filter by the product_id and location_id and only show if fast_stock_transfer_flag is true
      .where(warehouses: { id: selected_warehouse.id }) # Filter to include only matching warehouse
      .where("warehouses.id = (SELECT id FROM warehouses WHERE warehouses.location_id = locations.id ORDER BY warehouses.created_at LIMIT 1)") # Ensure it's the first warehouse
      .includes(:order) # Eager load orders to prevent N+1 queries
      .order("order_items.created_at") # Order the results by order_items' creation date

    # Fetch purchase lines for the product and selected warehouse
    purchase_lines = Purchases::PurchaseLine
      .joins(:purchase)
      .where(product_id: product.id, warehouse_id: selected_warehouse.id)
      .includes(:purchase) # Eager load purchases to prevent N+1 queries
      .order(:created_at)

    # Combine and sort movements by creation date
    movements = (stock_transfers + orders + purchase_lines).sort_by(&:created_at)

    # Initialize current stock
    current_stock = 0

    # Calculate final stock for each movement
    movements.map do |movement|
      if movement.is_a?(OrderItem)
        qty_out = movement.quantity
        qty_in = 0
        current_stock -= qty_out
        movement_type = "Venta"
      elsif movement.is_a?(Purchases::PurchaseLine)
        qty_in = movement.quantity
        qty_out = 0
        current_stock += qty_in
        movement_type = "Compra"
      else
        difference = false
        if movement.stock_transfer.is_adjustment?
          qty_in = movement.received_quantity || movement.quantity
          qty_out = 0
          current_stock += qty_in
          movement_type = "Adjustment"
        else
          if movement.stock_transfer.destination_warehouse_id == selected_warehouse.id
            qty_in = movement.received_quantity || movement.quantity
            qty_out = 0
            current_stock += qty_in
            difference = true if movement.received_quantity != movement.quantity
          else
            qty_in = 0
            qty_out = movement.quantity
            current_stock -= qty_out
            difference = true if movement.received_quantity != movement.quantity
          end
          movement_type = "Transferencia de Stock"
        end
      end

      # Convert movement to hash and add necessary keys
      movement_hash = movement.attributes.merge(
        final_stock: current_stock,
        qty_in: qty_in,
        qty_out: qty_out,
        difference: movement.is_a?(StockTransferLine) ? difference : false,
        type: movement_type
      )

      # Add custom attributes for display
      if movement.is_a?(OrderItem)
        movement_hash[:custom_id] = movement.order.custom_id
        movement_hash[:customer_name] = movement.order.customer.name
        movement_hash[:origin_warehouse_name] = movement.order.location.warehouses.first.name
      elsif movement.is_a?(Purchases::PurchaseLine)
        movement_hash[:custom_id] = movement.purchase.custom_id
        movement_hash[:vendor_name] = movement.purchase.vendor&.name
        movement_hash[:warehouse_name] = movement.warehouse&.name
      else
        movement_hash[:custom_id] = movement.stock_transfer.custom_id
        if movement.stock_transfer.origin_warehouse_id == selected_warehouse.id
          movement_hash[:origin_warehouse_name] = movement.stock_transfer.destination_warehouse&.name
          movement_hash[:destination_warehouse_name] = movement.stock_transfer.origin_warehouse&.name
        else
          movement_hash[:origin_warehouse_name] = movement.stock_transfer.origin_warehouse&.name
          movement_hash[:destination_warehouse_name] = movement.stock_transfer.destination_warehouse&.name
        end
      end

      movement_hash
    end
  end
end
