class CreateVoidedOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :voided_orders do |t|
      t.string :original_order_id, null: false
      t.string :original_order_custom_id, null: false
      t.bigint :location_id, null: false
      t.bigint :user_id, null: false
      t.jsonb :original_order_data, null: false, default: {}
      t.datetime :voided_at, null: false
      t.string :void_reason
      t.text :invoice_list
      t.timestamps

      t.index :original_order_id
      t.index :original_order_custom_id
      t.index :location_id
      t.index :user_id
    end

    add_foreign_key :voided_orders, :locations
    add_foreign_key :voided_orders, :users
  end
end
