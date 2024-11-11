class AddExtraFieldsToOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :request_id, :string
    add_column :orders, :preorder_id, :integer
    add_column :orders, :fast_payment_flag, :boolean, default: false
    add_column :orders, :fast_stock_transfer_flag, :boolean, default: false
    add_column :orders, :is_credit_sale, :boolean, default: false
    add_column :orders, :price_list_id, :integer

    add_index :orders, :request_id
    add_index :orders, :preorder_id
    add_index :orders, :price_list_id
    add_index :orders, :fast_payment_flag
    add_index :orders, :fast_stock_transfer_flag
    add_index :orders, :is_credit_sale
  end
end
