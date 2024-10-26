class CreateProductPackItems < ActiveRecord::Migration[7.2]
  def change
    create_table :product_pack_items do |t|
      t.references :product_pack, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1

      t.timestamps
    end
  end
end
