class CreatePlannedStockTransferLine < ActiveRecord::Migration[8.0]
  def change
    create_table :planned_stock_transfer_lines do |t|
      t.references :planned_stock_transfer, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :quantity, precision: 10, scale: 2, null: false
      t.decimal :fulfilled_quantity, precision: 10, scale: 2, default: 0, null: false

      t.timestamps
    end
  end
end
