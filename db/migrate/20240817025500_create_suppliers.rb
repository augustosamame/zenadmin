class CreateSuppliers < ActiveRecord::Migration[7.2]
  def change
    create_table :suppliers do |t|
      t.string :name, null: false
      t.string :custom_id, null: false
      t.references :sourceable, polymorphic: true, index: true
      t.references :region, null: false, foreign_key: true, index: true
      t.timestamps
    end

    add_index :suppliers, :custom_id, unique: true
  end
end
