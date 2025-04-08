class CreatePurchasesPurchaseOrderLines < ActiveRecord::Migration[8.0]
  def change
    create_table :purchases_purchase_order_lines do |t|
      t.references :purchase_order, null: false, foreign_key: { to_table: :purchases_purchase_orders }
      t.references :product, null: false, foreign_key: true
      t.integer :quantity
      t.monetize :unit_price

      t.timestamps
    end
  end
end
