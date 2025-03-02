class CreatePriceListItems < ActiveRecord::Migration[7.2]
  def change
    create_table :price_list_items do |t|
      t.references :price_list, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.monetize :price
      t.string :currency

      t.timestamps
    end

    add_index :price_list_items, [ :price_list_id, :product_id ], unique: true
  end
end
