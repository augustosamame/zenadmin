class CreateProductMinMaxPeriodMultipliers < ActiveRecord::Migration[7.2]
  def change
    create_table :product_min_max_period_multipliers do |t|
      t.references :product_min_max_stock, null: false, foreign_key: true
      t.string :year_month_period, null: false
      t.decimal :multiplier, null: false, default: 1.0

      t.timestamps
    end
  end
end
