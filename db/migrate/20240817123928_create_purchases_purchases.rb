class CreatePurchasesPurchases < ActiveRecord::Migration[7.2]
  def change
    create_table :purchases_purchases do |t|
      t.references :vendor, null: false, foreign_key: { to_table: :purchases_vendors }
      t.references :region, null: false, foreign_key: true
      t.datetime :purchase_date
      t.timestamps
    end
  end
end
