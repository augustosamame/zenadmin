class AddCreditFieldsToPayments < ActiveRecord::Migration[7.2]
  def change
    add_column :payments, :due_date, :datetime
    add_column :payments, :account_receivable_id, :integer
  end
end
