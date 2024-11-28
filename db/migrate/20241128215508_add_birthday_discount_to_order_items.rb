class AddBirthdayDiscountToOrderItems < ActiveRecord::Migration[7.2]
  def change
    add_column :order_items, :birthday_discount, :boolean, default: false
    add_column :order_items, :birthday_image, :text
  end
end
