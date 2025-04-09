class RemovePurchaseNumberFromPurchases < ActiveRecord::Migration[8.0]
  def change
    remove_column :purchases_purchases, :purchase_number, :string
  end
end
