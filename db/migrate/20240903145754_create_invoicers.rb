class CreateInvoicers < ActiveRecord::Migration[7.2]
  def change
    create_table :invoicers do |t|
      t.references :region, null: false, foreign_key: true
      t.string :name, null: false
      t.string :razon_social, null: false
      t.string :ruc, null: false
      t.integer :tipo_ruc, null: false, default: 0
      t.integer :einvoice_integrator, null: false, default: 0
      t.string :einvoice_url, null: false
      t.string :einvoice_api_key
      t.string :einvoice_api_secret
      t.boolean :default, null: false, default: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :invoicers, :name, unique: true
    add_index :invoicers, :ruc, unique: true
    add_index :invoicers, :default, unique: true
  end
end
