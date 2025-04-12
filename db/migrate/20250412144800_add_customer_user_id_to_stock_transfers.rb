class AddCustomerUserIdToStockTransfers < ActiveRecord::Migration[8.0]
  def change
    add_reference :stock_transfers, :customer_user, foreign_key: { to_table: :users }, null: true
  end
end
