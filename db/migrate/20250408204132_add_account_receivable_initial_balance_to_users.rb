class AddAccountReceivableInitialBalanceToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :account_receivable_initial_balance_cents, :integer, default: 0
    add_column :users, :account_receivable_initial_balance_currency, :string, default: "PEN"
  end
end
