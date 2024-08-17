class CreateProductCategoriesProductsJoinTable < ActiveRecord::Migration[7.2]
  def change
    create_table :product_categories_products do |t|
      t.references :product_category, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true

      t.timestamps
    end

    add_index :product_categories_products, [ :product_category_id, :product_id ], unique: true
  end
end
