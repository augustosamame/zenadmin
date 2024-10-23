class CreateDiscounts < ActiveRecord::Migration[7.2]
  def change
    create_table :discounts do |t|
      t.string :name, null: false
      t.integer :discount_type, default: 0
      t.decimal :discount_percentage, precision: 5, scale: 2
      t.decimal :discount_fixed_amount, precision: 5, scale: 2
      t.integer :group_discount_payed_quantity
      t.integer :group_discount_free_quantity
      t.datetime :start_datetime
      t.datetime :end_datetime
      t.integer :status, default: 0
      t.integer :matching_product_ids, array: true, default: []

      t.timestamps
    end
    add_index :discounts, :matching_product_ids, using: 'gin'
    add_index :discounts, :status
    add_index :discounts, :discount_type
    add_index :discounts, :start_datetime
    add_index :discounts, :end_datetime
  end
end