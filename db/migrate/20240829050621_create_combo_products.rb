class CreateComboProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :combo_products do |t|
      t.string :name, null: false
      t.integer :product_1_id, null: false
      t.integer :product_2_id, null: false
      t.integer :qty_1, null: false
      t.integer :qty_2, null: false
      t.integer :normal_price_cents, null: false
      t.integer :price_cents, null: false
      t.string :currency, null: false, default: 'PEN'
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
