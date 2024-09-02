class CreateOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :seller, null: false, foreign_key: { to_table: :users }, index: true
      t.references :location, null: false, foreign_key: true, index: true
      t.references :region, null: false, foreign_key: true, index: true
      t.string :custom_id, null: false
      t.integer :order_recipient_id
      t.integer :total_price_cents
      t.integer :total_discount_cents
      t.integer :shipping_price_cents
      t.string :currency, default: "PEN"
      t.integer :cart_id
      t.integer :shipping_address_id
      t.integer :billing_address_id
      t.boolean :coupon_applied, default: false
      t.text :customer_note
      t.text :seller_note
      t.integer :active_invoice_id
      t.boolean :invoice_id_required, default: false # dni or RUC required
      t.datetime :order_date
      t.integer :origin, default: 0
      t.integer :stage, default: 1
      t.integer :payment_status, default: 0
      t.integer :status, default: 0

      t.timestamps
    end

    add_index :orders, :custom_id, unique: true
    add_index :orders, :active_invoice_id, unique: true
    add_index :orders, :cart_id
    add_index :orders, [ :location_id, :status, :order_date, :seller_id ]
  end
end
