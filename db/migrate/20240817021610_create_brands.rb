class CreateBrands < ActiveRecord::Migration[7.2]
  def change
    create_table :brands do |t|
      t.string :name, null: false
      t.text :image
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
