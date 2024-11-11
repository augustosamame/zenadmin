class CreateProductMinMaxStocks < ActiveRecord::Migration[7.2]
  def change
    create_table :product_min_max_stocks do |t|
      t.references :product, null: false, foreign_key: true
      t.references :warehouse, null: false, foreign_key: true
      t.integer :min_stock
      t.integer :max_stock

      t.timestamps
    end
  end
end
