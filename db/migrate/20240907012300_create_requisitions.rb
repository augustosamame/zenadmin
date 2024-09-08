class CreateRequisitions < ActiveRecord::Migration[7.1]
  def change
    create_table :requisitions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :location, null: false, foreign_key: true
      t.references :warehouse, null: false, foreign_key: true
      t.string :custom_id, null: false
      t.string :stage, default: 'pending'
      t.date :requisition_date, null: false
      t.text :comments
      t.integer :requisition_type, default: 0, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    create_table :requisition_lines do |t|
      t.references :requisition, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :automatic_quantity, null: false
      t.integer :presold_quantity
      t.integer :manual_quantity
      t.integer :supplied_quantity
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :requisitions, :custom_id, unique: true
  end
end
