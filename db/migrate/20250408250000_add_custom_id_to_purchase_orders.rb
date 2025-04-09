class AddCustomIdToPurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :purchases_purchase_orders, :custom_id, :string
    
    # Copy data from purchase_order_number to custom_id
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE purchases_purchase_orders
          SET custom_id = purchase_order_number
        SQL
      end
    end
    
    # Add index and constraints after data is copied
    add_index :purchases_purchase_orders, :custom_id, unique: true
  end
end
