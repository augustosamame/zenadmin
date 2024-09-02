class CreateLocations < ActiveRecord::Migration[7.2]
  def change
    create_table :locations do |t|
      t.references :region, null: false, foreign_key: true
      t.string :name
      t.string :address
      t.string :phone
      t.string :email
      t.string :latitude
      t.string :longitude
      t.integer :status, default: 0
      t.timestamps
    end
  end
end
