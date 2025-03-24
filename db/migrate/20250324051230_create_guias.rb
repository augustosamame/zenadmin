class CreateGuias < ActiveRecord::Migration[7.0]
  def change
    create_table :guias do |t|
      t.references :stock_transfer, null: false, foreign_key: true
      t.references :guia_series, null: false, foreign_key: true
      t.string :custom_id
      t.integer :amount
      t.string :currency, default: "PEN"
      t.integer :guia_type, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.integer :sunat_status, default: 0, null: false
      t.text :guia_sunat_sent_text
      t.json :guia_sunat_response
      t.string :guia_url

      t.timestamps
    end
  end
end
