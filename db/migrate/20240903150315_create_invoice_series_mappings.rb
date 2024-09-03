class CreateInvoiceSeriesMappings < ActiveRecord::Migration[7.2]
  def change
    create_table :invoice_series_mappings do |t|
      t.references :invoice_series, null: false, foreign_key: true
      t.references :location, null: false, foreign_key: true
      t.references :payment_method, null: false, foreign_key: true

      t.timestamps
    end
  end
end
