class CreatePurchasesVendors < ActiveRecord::Migration[7.2]
  def change
    create_table :purchases_vendors do |t|
      t.string :name, null: false
      t.timestamps
    end
  end
end
