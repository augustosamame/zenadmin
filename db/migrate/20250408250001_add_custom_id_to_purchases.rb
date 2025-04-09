class AddCustomIdToPurchases < ActiveRecord::Migration[8.0]
  def change
    add_column :purchases_purchases, :custom_id, :string
    
    # Copy data from purchase_number to custom_id
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE purchases_purchases
          SET custom_id = purchase_number
        SQL
      end
    end
    
    # Add index and constraints after data is copied
    add_index :purchases_purchases, :custom_id, unique: true
  end
end
