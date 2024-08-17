class CreatePurchasesPurchaseLines < ActiveRecord::Migration[7.2]
  def change
    create_table :purchases_purchase_lines do |t|
      t.references :purchase, foreign_key: { to_table: :purchases_purchases }
      t.references :product, foreign_key: { to_table: :products }
      t.integer :quantity, null: false
      t.decimal :price, precision: 10, scale: 2
      t.timestamps
    end
  end
end