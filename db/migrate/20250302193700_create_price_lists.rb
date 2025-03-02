class CreatePriceLists < ActiveRecord::Migration[7.2]
  def change
    create_table :price_lists do |t|
      t.string :name, null: false
      t.integer :status, default: 0

      t.timestamps
    end

    add_index :price_lists, :name, unique: true
  end
end
