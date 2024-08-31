class CreateCustomNumberings < ActiveRecord::Migration[7.2]
  def change
    create_table :custom_numberings do |t|
      t.integer :record_type, default: 0, null: false
      t.string :prefix, null: false, default: ""
      t.integer :next_number, null: false, default: 1
      t.integer :length, default: 5, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :custom_numberings, [ :record_type, :prefix ], unique: true
  end
end
