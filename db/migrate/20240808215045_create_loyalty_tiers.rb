class CreateLoyaltyTiers < ActiveRecord::Migration[7.2]
  def change
    create_table :loyalty_tiers do |t|
      t.string :name, null: false
      t.integer :requirements_orders_count
      t.decimal :requirements_total_amount
      t.decimal :discount_percentage
      t.integer :free_product_id
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
