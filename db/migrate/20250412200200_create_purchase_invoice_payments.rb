class CreatePurchaseInvoicePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_invoice_payments do |t|
      t.references :purchase_invoice, null: false, foreign_key: true
      t.references :purchase_payment, null: false, foreign_key: true
      t.integer :amount_cents, default: 0, null: false
      t.string :currency

      t.timestamps
    end
  end
end
