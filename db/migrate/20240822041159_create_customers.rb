class CreateCustomers < ActiveRecord::Migration[7.2]
  def change
    create_table :customers do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :doc_type, default: 0
      t.string :doc_id
      t.datetime :birthdate
      t.jsonb :avatar_data
      t.integer :last_cart_id
      t.integer :pricelist_id
      t.integer :points_balance, default: 0
      t.string :referral_code
      t.references :referrer, foreign_key: { to_table: :users }, null: true
      t.boolean :wants_factura, default: false
      t.string :factura_ruc
      t.string :factura_razon_social
      t.string :factura_direccion
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
