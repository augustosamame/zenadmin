class AddStartEndTimesToProductPacks < ActiveRecord::Migration[7.2]
  def change
    add_column :product_packs, :start_datetime, :datetime
    add_column :product_packs, :end_datetime, :datetime
    add_index :product_packs, :start_datetime
    add_index :product_packs, :end_datetime
  end
end
