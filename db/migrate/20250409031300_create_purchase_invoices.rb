class CreatePurchaseInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_invoices do |t|
      t.references :purchase, null: false, foreign_key: { to_table: :purchases_purchases }
      t.references :vendor, null: false, foreign_key: { to_table: :purchases_vendors }
      t.date :purchase_invoice_date, null: false
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "PEN"
      t.integer :purchase_invoice_type, default: 0, null: false
      t.integer :payment_status, default: 0, null: false
      t.date :planned_payment_date, null: false
      t.string :custom_id

      t.timestamps
    end

    add_index :purchase_invoices, :payment_status
    add_index :purchase_invoices, :purchase_invoice_type
  end
end
