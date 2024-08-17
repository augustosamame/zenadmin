class CreateProductCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :product_categories do |t|
      t.string :name, null: false
      t.references :parent, foreign_key: { to_table: :product_categories }, null: true
      t.text :image
      t.integer :product_category_type, default: 0
      t.integer :category_order, default: 0
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
