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
  end

  def fetch_kardex_movements
    product = Product.find(params[:product_id])
    selected_warehouse = params[:warehouse_id].present? ? Warehouse.find(params[:warehouse_id]) : @current_warehouse
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

    # Combine and sort movements by creation date
    movements = (stock_transfers + orders).sort_by(&:created_at)

    # Initialize current stock
    current_stock = 0

    # Calculate final stock for each movement
    @movements = movements.map do |movement|
      if movement.is_a?(OrderItem)
        qty_out = movement.quantity
        qty_in = 0
        current_stock -= qty_out
      else
        if movement.stock_transfer.is_adjustment?
          qty_in = movement.received_quantity || movement.quantity
          qty_out = 0
          current_stock += qty_in
        else
          if movement.stock_transfer.destination_warehouse_id == selected_warehouse.id
            qty_in = movement.received_quantity || movement.quantity
            qty_out = 0
            current_stock += qty_in
          else
            qty_in = 0
            qty_out = movement.quantity
            current_stock -= qty_out
          end
        end
      end

      # Convert movement to hash and add necessary keys
      movement_hash = movement.attributes.merge(
        final_stock: current_stock,
        qty_in: qty_in,
        qty_out: qty_out,
        type: (movement.class.name == "StockTransferLine" && movement.stock_transfer.is_adjustment?) ? "Adjustment" : movement.class.name
      )

      # Add custom attributes for display
      if movement.is_a?(OrderItem)
        movement_hash[:custom_id] = movement.order.custom_id
        movement_hash[:customer_name] = movement.order.customer.name
        movement_hash[:origin_warehouse_name] = movement.order.location.warehouses.first.name
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

    # Respond with Turbo Stream or HTML
    respond_to do |format|
      format.turbo_stream
      # format.html { render partial: 'admin/inventorykardex/kardex_table', locals: { movements: @movements } }
    end
  end
end
