class CreateUnitOfMeasures < ActiveRecord::Migration[8.0]
  def change
    create_table :unit_of_measures do |t|
      t.string :name, null: false
      t.string :abbreviation, null: false
      t.string :sunat_code, null: false
      t.references :reference_unit, foreign_key: { to_table: :unit_of_measures }, null: true
      t.decimal :multiplier, precision: 10, scale: 4, null: false, default: 1.0
      t.integer :status, null: false, default: 0
      t.boolean :default, null: false, default: false
      t.text :notes
      t.timestamps
    end
    add_index :unit_of_measures, :name, unique: true

    # Create default "Unidad" record
    reversible do |dir|
      dir.up do
        execute <<-SQL
          INSERT INTO unit_of_measures (name, abbreviation, sunat_code, multiplier, status, "default", created_at, updated_at)
          VALUES ('Unidad', 'un', 'NIU', 1.0, 0, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        SQL
      end
    end
  end
end
