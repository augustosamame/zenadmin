class AddDniAddressToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :dni_address, :string, null: true
  end
end
