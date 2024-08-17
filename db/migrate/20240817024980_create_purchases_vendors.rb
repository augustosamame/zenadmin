class CreatePurchasesVendors < ActiveRecord::Migration[7.2]
  def change
    create_table :purchases_vendors do |t|
      t.string :name, null: false
      t.references :region, null: false, foreign_key: true
      t.timestamps
    end
  end
end
