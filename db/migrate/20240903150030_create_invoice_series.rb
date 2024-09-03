class CreateInvoiceSeries < ActiveRecord::Migration[7.2]
  def change
    create_table :invoice_series do |t|
      t.references :invoicer, null: false, foreign_key: true
      t.integer :comprobante_type, null: false
      t.string :prefix, null: false
      t.integer :next_number, null: false
      t.integer :status, null: false, default: 0
      t.text :comments

      t.timestamps
    end
  end
end
