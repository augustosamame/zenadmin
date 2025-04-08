class CreatePurchasesPurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :purchases_purchase_orders do |t|
      t.string :purchase_order_number
      t.references :region, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :vendor, null: false, foreign_key: { to_table: :purchases_vendors }
      t.date :order_date
      t.text :notes
      t.integer :status, default: 0

      t.timestamps
    end
    
    add_index :purchases_purchase_orders, :purchase_order_number, unique: true
  end
end
