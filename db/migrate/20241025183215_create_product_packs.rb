class CreateProductPacks < ActiveRecord::Migration[7.2]
  def change
    create_table :product_packs do |t|
      t.string :name, null: false
      t.text :description
      t.integer :price_cents, null: false
      t.string :currency, null: false, default: 'PEN'
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
