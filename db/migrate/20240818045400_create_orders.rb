class CreateOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :location, null: false, foreign_key: true
      t.references :region, null: false, foreign_key: true
      t.integer :total_price_cents
      t.integer :total_discount_cents
      t.datetime :order_date

      t.timestamps
    end
  end
end
