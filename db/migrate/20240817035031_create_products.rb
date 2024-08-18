class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.string :sku, null: false
      t.string :name, null: false
      t.integer :brand_id
      t.text :description, null: false
      t.references :sourceable, polymorphic: true, index: true
      t.text :image
      t.string :permalink, null: false
      t.integer :price_cents, null: false
      t.integer :discounted_price_cents
      t.text :meta_keywords
      t.text :meta_description
      t.boolean :stockable, default: true
      t.datetime :available_at
      t.datetime :deleted_at
      t.integer :product_order, default: 0
      t.integer :status, default: 0
      t.decimal :weight, precision: 10, scale: 2

      t.timestamps
    end
  end
end
