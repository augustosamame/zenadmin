class CreatePeriodicInventories < ActiveRecord::Migration[7.2]
  def change
    create_table :periodic_inventories do |t|
      t.references :warehouse, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :snapshot_date, null: false
      t.integer :inventory_type, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.timestamps
    end

    add_index :periodic_inventories, :status
    add_index :periodic_inventories, :snapshot_date
    add_index :periodic_inventories, :inventory_type
  end
end
