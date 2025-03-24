class CreatePlannedStockTransfer < ActiveRecord::Migration[8.0]
  def change
    create_table :planned_stock_transfers do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :origin_warehouse, null: false, foreign_key: { to_table: :warehouses }, index: true
      t.references :destination_warehouse, null: true, foreign_key: { to_table: :warehouses }, index: true
      t.references :order, null: true, foreign_key: true, index: true
      t.string :custom_id, null: false
      t.datetime :planned_date
      t.text :comments
      t.integer :status, default: 0, null: false
      t.string :fulfillment_status, default: "pending"

      t.timestamps
    end

    add_index :planned_stock_transfers, :custom_id, unique: true
    add_index :planned_stock_transfers, :planned_date
    add_index :planned_stock_transfers, :status
    add_index :planned_stock_transfers, :fulfillment_status
  end
end
