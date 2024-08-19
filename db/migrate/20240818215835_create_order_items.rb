class CreateOrderItems < ActiveRecord::Migration[7.2]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :quantity, precision: 10, scale: 2
      t.integer :price_cents
      t.integer :discounted_price_cents
      t.string :currency, default: "PEN"

      t.timestamps
    end
  end
end
