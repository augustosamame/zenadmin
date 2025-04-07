class CreateTransportista < ActiveRecord::Migration[8.0]
  def change
    create_table :transportistas do |t|
      t.integer :transportista_type, default: 0, null: false
      t.integer :doc_type, default: 0, null: false
      t.string :first_name
      t.string :last_name
      t.string :license_number
      t.string :dni_number
      t.string :razon_social
      t.string :ruc_number
      t.string :vehicle_plate
      t.string :numero_mtc
      t.string :m1l_indicator
      t.integer :transportista_order, default: 0
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
