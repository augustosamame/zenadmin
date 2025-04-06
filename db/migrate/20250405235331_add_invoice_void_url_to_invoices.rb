class AddInvoiceVoidUrlToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :void_url, :string
    add_column :invoices, :void_sunat_response, :text
  end
end
