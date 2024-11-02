class AddGroupDiscountPercentageOffToDiscounts < ActiveRecord::Migration[7.2]
  def change
    add_column :discounts, :group_discount_percentage_off, :decimal, precision: 5, scale: 2
  end
end
