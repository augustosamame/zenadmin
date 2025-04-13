class AllowNullPurchaseIdInPurchaseInvoices < ActiveRecord::Migration[8.0]
  def change
    change_column_null :purchase_invoices, :purchase_id, true
  end
end
