class CreateCommissionRanges < ActiveRecord::Migration[7.2]
  def change
    create_table :commission_ranges do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :min_sales, precision: 10, scale: 2, null: false
      t.decimal :max_sales, precision: 10, scale: 2
      t.decimal :commission_percentage, precision: 5, scale: 2, null: false
      t.references :location, null: false, foreign_key: true

      t.timestamps
    end

    add_index :commission_ranges, :min_sales
    add_index :commission_ranges, :max_sales
  end
end
