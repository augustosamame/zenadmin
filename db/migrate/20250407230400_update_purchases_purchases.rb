class UpdatePurchasesPurchases < ActiveRecord::Migration[8.0]
  def change
    change_table :purchases_purchases do |t|
      t.references :user, null: false, foreign_key: true
      t.references :purchase_order, foreign_key: { to_table: :purchases_purchase_orders }, null: true
      t.rename :custom_id, :purchase_number
      t.text :notes
    end
  end
end
