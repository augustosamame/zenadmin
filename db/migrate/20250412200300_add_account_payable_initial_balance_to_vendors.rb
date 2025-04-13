class AddAccountPayableInitialBalanceToVendors < ActiveRecord::Migration[8.0]
  def change
    add_column :purchases_vendors, :account_payable_initial_balance, :decimal, precision: 10, scale: 2, default: 0
  end
end
