class CreateStockTransfers < ActiveRecord::Migration[7.2]
  def change
    create_table :stock_transfers do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :origin_warehouse, null: true, foreign_key: { to_table: :warehouses }, index: true
      t.references :destination_warehouse, null: true, foreign_key: { to_table: :warehouses }, index: true
      t.string :custom_id, null: false
      t.string :guia
      t.datetime :transfer_date, null: false
      t.text :comments
      t.boolean :is_adjustment, default: false
      t.integer :adjustment_type, default: 0
      t.references :periodic_inventory, null: true, foreign_key: { to_table: :periodic_inventories }, index: true
      t.string :stage, default: 'pending'
      t.integer :status, default: 0

      t.timestamps
    end

    add_index :stock_transfers, :custom_id, unique: true
    add_index :stock_transfers, :stage
    add_index :stock_transfers, :status
    add_index :stock_transfers, :transfer_date
  end
end
