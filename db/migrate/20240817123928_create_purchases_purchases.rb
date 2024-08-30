class CreatePurchasesPurchases < ActiveRecord::Migration[7.2]
  def change
    create_table :purchases_purchases do |t|
      t.references :vendor, null: false, foreign_key: { to_table: :purchases_vendors }, index: true
      t.references :region, null: false, foreign_key: true, index: true
      t.string :custom_id, null: false
      t.datetime :purchase_date
      t.timestamps
    end

    add_index :purchases_purchases, :custom_id, unique: true
  end
end
