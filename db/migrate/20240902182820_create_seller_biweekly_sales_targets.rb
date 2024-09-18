class CreateSellerBiweeklySalesTargets < ActiveRecord::Migration[7.2]
  def change
    create_table :seller_biweekly_sales_targets do |t|
      t.references :seller, null: false, foreign_key: { to_table: :users }
      t.references :user, null: false, foreign_key: { to_table: :users }
      t.string :year_month_period # e.g. 2024_08_I, 2024_08_II
      t.integer :sales_target_cents, null: false
      t.string :currency, default: "PEN", null: false
      t.decimal :target_commission, precision: 5, scale: 2, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end
    add_index :seller_biweekly_sales_targets, [ :seller_id, :year_month_period ], unique: true, name: 'index_targets_on_seller_id_and_year_month_period'
  end
end
