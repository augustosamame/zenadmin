class CreateSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :settings do |t|
      t.string :name, null: false
      t.string :localized_name, null: false
      t.integer :data_type, default: 0
      t.boolean :internal, default: true
      t.string :string_value
      t.integer :integer_value
      t.float :float_value
      t.datetime :datetime_value
      t.boolean :boolean_value
      t.jsonb :hash_value
      t.integer :status, default: 0

      t.timestamps
    end
    add_index :settings, :name, unique: true
  end
end
