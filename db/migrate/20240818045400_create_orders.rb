class CreateOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :location, null: false, foreign_key: true
      t.references :region, null: false, foreign_key: true
      t.integer :order_recipient_id
      t.integer :total_price_cents
      t.integer :total_discount_cents
      t.integer :shipping_price_cents
      t.string :currency, default: "PEN"
      t.integer :cart_id
      t.integer :shipping_address_id
      t.integer :billing_address_id
      t.boolean :coupon_applied, default: false
      t.integer :stage, default: 0
      t.integer :payment_status, default: 0
      t.integer :status, default: 0
      t.text :customer_note
      t.text :seller_note
      t.integer :active_invoice_id
      t.boolean :invoice_id_required, default: false # dni or RUC required
      t.datetime :order_date

      t.timestamps
    end
    add_index :orders, :active_invoice_id, unique: true
    add_index :orders, :cart_id
    add_index :orders, :order_date
  end
end
