class AddNotesToPurchaseInvoicePayments < ActiveRecord::Migration[8.0]
  def change
    add_column :purchase_invoice_payments, :notes, :text
  end
end
