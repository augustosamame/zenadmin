module Services
  module Inventory
    class PurchaseItemService
      def initialize(purchase)
        @purchase = purchase
      end

      def update_inventory
        ActiveRecord::Base.transaction do
          # Group purchase lines by warehouse
          warehouse_groups = @purchase.purchase_lines.group_by(&:warehouse_id)
          
          # Create a stock transfer for each warehouse
          warehouse_groups.each do |warehouse_id, purchase_lines|
            next if warehouse_id.nil?
            
            # Create a new stock transfer from vendor to warehouse
            stock_transfer = StockTransfer.new(
              user_id: @purchase.user_id,
              origin_warehouse_id: nil, # No origin warehouse for vendor transfers
              destination_warehouse_id: warehouse_id,
              vendor_id: @purchase.vendor_id,
              from_vendor: "1", # Flag to indicate this is a vendor transfer
              transfer_date: Time.zone.now,
              comments: "Creado automáticamente desde la compra #{@purchase.custom_id}"
            )
            
            # Add lines for each product in the purchase for this warehouse
            purchase_lines.each do |purchase_line|
              next if purchase_line.product.nil? || purchase_line.quantity <= 0
              
              stock_transfer.stock_transfer_lines.build(
                product_id: purchase_line.product_id,
                quantity: purchase_line.quantity
              )
            end
            
            # Save the stock transfer (it will be in pending stage by default)
            unless stock_transfer.save
              Rails.logger.error "Failed to create StockTransfer from Purchase #{@purchase.id}: #{stock_transfer.errors.full_messages.join(", ")}"
              raise ActiveRecord::Rollback
            end
            
            # Automatically start the transfer for vendor transfers
            stock_transfer.start_transfer! if stock_transfer.vendor_id.present?
          end
        end
      end
      
      private
      
      # This method is no longer used but kept for reference
      def update_inventory_directly
        ActiveRecord::Base.transaction do
          @purchase.purchase_lines.each do |purchase_line|
            # Skip if no warehouse is specified
            next unless purchase_line.warehouse.present?
            
            # Use the warehouse specified in the purchase line
            warehouse = purchase_line.warehouse
            
            product_to_update = warehouse.warehouse_inventories.find_by(product_id: purchase_line.product_id)
            
            if product_to_update.present?
              # Add to existing inventory
              product_to_update.update!(stock: product_to_update.stock + purchase_line.quantity)
            else
              # Create new inventory record
              WarehouseInventory.create!(
                warehouse: warehouse, 
                product: purchase_line.product, 
                stock: purchase_line.quantity
              )
            end
            
            # Check if there are any preorders for this product and fulfill them
            fulfill_preorders(purchase_line.product_id, warehouse.id)
          end
        end
      end
      
      def fulfill_preorders(product_id, warehouse_id)
        # Find any preorders for this product
        preorders = Preorder.where(product_id: product_id, warehouse_id: warehouse_id)
                            .where("quantity > 0")
                            .order(created_at: :asc)
        
        return if preorders.empty?
        
        # Get the current inventory level
        inventory = WarehouseInventory.find_by(product_id: product_id, warehouse_id: warehouse_id)
        return unless inventory.present?
        
        available_stock = inventory.stock
        
        # Fulfill preorders as much as possible
        preorders.each do |preorder|
          if available_stock <= 0
            break
          end
          
          if available_stock >= preorder.quantity
            # Fully fulfill this preorder
            available_stock -= preorder.quantity
            preorder.update!(quantity: 0, fulfilled_at: Time.current)
          else
            # Partially fulfill this preorder
            preorder.update!(quantity: preorder.quantity - available_stock, partially_fulfilled_at: Time.current)
            available_stock = 0
            break
          end
        end
        
        # Update the inventory with the remaining stock
        inventory.update!(stock: available_stock)
      end
    end
  end
end
