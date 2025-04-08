class AddContactDetailsToPurchasesVendors < ActiveRecord::Migration[8.0]
  def change
    add_column :purchases_vendors, :contact_name, :string
    add_column :purchases_vendors, :email, :string
    add_column :purchases_vendors, :phone, :string
    add_column :purchases_vendors, :address, :string
    add_column :purchases_vendors, :tax_id, :string
    add_column :purchases_vendors, :notes, :text
  end
end
