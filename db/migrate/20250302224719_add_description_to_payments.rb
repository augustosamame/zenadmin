class AddDescriptionToPayments < ActiveRecord::Migration[7.2]
  def change
    add_column :payments, :description, :string
  end
end
