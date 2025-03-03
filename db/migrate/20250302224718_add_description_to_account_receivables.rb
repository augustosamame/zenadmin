class AddDescriptionToAccountReceivables < ActiveRecord::Migration[7.2]
  def change
    add_column :account_receivables, :description, :string
  end
end
