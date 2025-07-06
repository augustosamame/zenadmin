class AddMaxDiscountToLocations < ActiveRecord::Migration[8.0]
  def change
    add_column :locations, :max_discount, :decimal, precision: 5, scale: 2
  end
end
