class CreatePreorders < ActiveRecord::Migration[7.2]
  def change
    create_table :preorders do |t|
      t.references :product, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.references :warehouse, null: false, foreign_key: true
      t.decimal :quantity, null: false
      t.decimal :fulfilled_quantity, null: false, default: 0
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
