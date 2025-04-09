module Services
  module Inventory
    class PurchaseItemService
      def initialize(purchase)
        @purchase = purchase
      end

      def update_inventory
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
      
      private
      
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
