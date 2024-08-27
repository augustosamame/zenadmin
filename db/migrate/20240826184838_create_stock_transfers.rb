class CreateStockTransfers < ActiveRecord::Migration[7.2]
  def change
    create_table :stock_transfers do |t|
      t.references :user, null: false, foreign_key: true
      t.references :origin_warehouse, null: true, foreign_key: { to_table: :warehouses }
      t.references :destination_warehouse, null: true, foreign_key: { to_table: :warehouses }
      t.datetime :transfer_date, null: false
      t.text :comments
      t.integer :stage, default: 0
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
