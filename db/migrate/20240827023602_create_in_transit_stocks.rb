class CreateInTransitStocks < ActiveRecord::Migration[7.2]
  def change
    create_table :in_transit_stocks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :stock_transfer, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.references :origin_warehouse, null: false, foreign_key: { to_table: :warehouses }
      t.references :destination_warehouse, null: false, foreign_key: { to_table: :warehouses }

      t.timestamps
    end
  end
end
