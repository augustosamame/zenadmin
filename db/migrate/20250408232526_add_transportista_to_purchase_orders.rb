class AddTransportistaToPurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    add_reference :purchases_purchase_orders, :transportista, null: true, foreign_key: true
  end
end
