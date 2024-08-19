class CreateOrderSellers < ActiveRecord::Migration[7.2]
  def change
    create_table :order_sellers do |t|
      t.references :order, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :percentage, null: false
      t.integer :amount_cents, null: false
      t.string :currency, default: "PEN"
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
