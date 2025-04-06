class AddAddressToInvoicer < ActiveRecord::Migration[8.0]
  def change
    add_column :invoicers, :address, :string
  end
end
