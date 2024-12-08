class CreateExternalInvoices < ActiveRecord::Migration[7.2]
  def change
    create_table :external_invoices do |t|
      t.references :order, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string :currency, null: false
      t.string :custom_id, null: false
      t.integer :invoice_type, null: false, default: 0
      t.integer :sunat_status, null: false, default: 1
      t.string :invoice_url
      t.integer :status, null: false, default: 1

      t.timestamps
    end

    add_index :external_invoices, [ :custom_id, :invoice_type ], unique: true
  end
end
