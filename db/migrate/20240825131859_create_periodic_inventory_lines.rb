class CreatePeriodicInventoryLines < ActiveRecord::Migration[7.2]
  def change
    create_table :periodic_inventory_lines do |t|
      t.references :periodic_inventory, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :stock, null: false
      t.integer :status, default: 0

      t.timestamps
    end

    add_index :periodic_inventory_lines, :status
  end
end
