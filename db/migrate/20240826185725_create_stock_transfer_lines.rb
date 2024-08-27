class CreateStockTransferLines < ActiveRecord::Migration[7.2]
  def change
    create_table :stock_transfer_lines do |t|
      t.references :stock_transfer, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :quantity, precision: 10, scale: 2, null: false

      t.timestamps
    end
  end
end
