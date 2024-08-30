class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.string :custom_id, null: false
      t.string :name, null: false
      t.integer :brand_id
      t.text :description, null: false
      t.references :sourceable, polymorphic: true, index: true
      t.string :permalink, null: false
      t.integer :price_cents, null: false
      t.integer :discounted_price_cents
      t.text :meta_keywords
      t.text :meta_description
      t.boolean :stockable, default: true
      t.boolean :is_test_product, default: false
      t.datetime :available_at
      t.datetime :deleted_at
      t.integer :product_order, default: 0
      t.integer :status, default: 0
      t.decimal :weight, precision: 10, scale: 2

      t.timestamps
    end

    add_index :products, :custom_id, unique: true
    add_index :products, :name
    add_index :products, :status
    add_index :products, :product_order
    add_index :products, :is_test_product
  end
end
