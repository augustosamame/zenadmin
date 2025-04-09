class RemovePurchaseOrderNumberFromPurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    remove_column :purchases_purchase_orders, :purchase_order_number, :string
  end
end
