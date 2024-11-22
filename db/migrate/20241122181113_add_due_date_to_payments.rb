class AddDueDateToPayments < ActiveRecord::Migration[7.2]
  def change
    add_column :payments, :due_date, :datetime
  end
end
