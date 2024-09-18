class CreateCommissionRanges < ActiveRecord::Migration[7.2]
  def change
    create_table :commission_ranges do |t|
      t.references :user, null: false, foreign_key: true
      t.string :year_month_period # e.g. 2024_08_I, 2024_08_II
      t.decimal :min_sales, precision: 10, scale: 2, null: false
      t.decimal :max_sales, precision: 10, scale: 2
      t.decimal :commission_percentage, precision: 5, scale: 2, null: false
      t.references :location, null: false, foreign_key: true

      t.timestamps
    end

    add_index :commission_ranges, :min_sales
    add_index :commission_ranges, :max_sales
    add_index :commission_ranges, [ :location_id, :year_month_period ], name: 'index_commission_ranges_on_location_id_and_year_month_period'
  end
end
