class CreateWarehouseInventories < ActiveRecord::Migration[7.2]
  def change
    create_table :warehouse_inventories do |t|
      t.references :warehouse, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :stock, null: false, default: 0

      t.timestamps
    end
    add_index :warehouse_inventories, [:warehouse_id, :product_id], unique: true
  end
end
