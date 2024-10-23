class CreateDiscountFilters < ActiveRecord::Migration[7.2]
  def change
    create_table :discount_filters do |t|
      t.references :discount, null: false, foreign_key: true
      t.references :filterable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
