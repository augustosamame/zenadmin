class CreateInvoices < ActiveRecord::Migration[7.2]
  def change
    create_table :invoices do |t|
      t.references :order, null: false, foreign_key: true
      t.references :invoice_series, null: false, foreign_key: true
      t.references :payment_method, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "PEN"
      t.string :custom_id, null: false
      t.integer :invoice_type, default: 0, null: false
      t.integer :sunat_status, default: 0, null: false
      t.text :invoice_sunat_sent_text
      t.text :invoice_sunat_response
      t.text :invoice_url
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :invoices, [ :custom_id, :invoice_type, :status ], unique: true
    add_index :invoices, :sunat_status
  end
end
