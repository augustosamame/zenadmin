class AddCashierLinkedIdToPaymentMethod < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_methods, :cashier_linked_id, :integer, null: true
  end
end
