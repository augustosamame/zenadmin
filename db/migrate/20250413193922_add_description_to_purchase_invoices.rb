class AddDescriptionToPurchaseInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :purchase_invoices, :description, :string
  end
end
