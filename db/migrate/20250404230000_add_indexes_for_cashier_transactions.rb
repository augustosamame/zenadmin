class AddIndexesForCashierTransactions < ActiveRecord::Migration[8.0]
  def change
    # Add index to cashier_transactions for faster lookups by cashier_shift_id
    add_index :cashier_transactions, :cashier_shift_id, name: 'index_cashier_transactions_on_cashier_shift_id' unless index_exists?(:cashier_transactions, :cashier_shift_id)
    
    # Add index for payment_method_id to speed up joins and lookups
    add_index :cashier_transactions, :payment_method_id, name: 'index_cashier_transactions_on_payment_method_id' unless index_exists?(:cashier_transactions, :payment_method_id)
    
    # Add index for transactable polymorphic association
    add_index :cashier_transactions, [:transactable_type, :transactable_id], name: 'index_cashier_transactions_on_transactable' unless index_exists?(:cashier_transactions, [:transactable_type, :transactable_id])
    
    # Add index for payments to speed up lookups related to cashier shifts
    add_index :payments, :cashier_shift_id, name: 'index_payments_on_cashier_shift_id' unless index_exists?(:payments, :cashier_shift_id)
    
    # Add index for commissions to speed up the sales_by_seller calculation
    add_index :commissions, [:order_id, :user_id], name: 'index_commissions_on_order_id_and_user_id' unless index_exists?(:commissions, [:order_id, :user_id])
  end
end
