class AddProductPackIdToOrderItems < ActiveRecord::Migration[7.0]
  def change
    add_reference :order_items, :product_pack, null: true, foreign_key: true
  end
end
