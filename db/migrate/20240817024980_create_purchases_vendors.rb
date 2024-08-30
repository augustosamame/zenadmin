class CreatePurchasesVendors < ActiveRecord::Migration[7.2]
  def change
    create_table :purchases_vendors do |t|
      t.string :name, null: false
      t.string :custom_id, null: false
      t.references :region, null: false, foreign_key: true, index: true
      t.timestamps
    end

    add_index :purchases_vendors, :custom_id, unique: true
  end
end
