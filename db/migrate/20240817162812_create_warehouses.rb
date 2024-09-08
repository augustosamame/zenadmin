class CreateWarehouses < ActiveRecord::Migration[7.2]
  def change
    create_table :warehouses do |t|
      t.string :name, null: false
      t.integer :location_id
      t.boolean :is_main, default: false
      t.references :region, null: false, foreign_key: true
      t.timestamps
    end
  end
end
