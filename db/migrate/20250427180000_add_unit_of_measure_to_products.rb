class AddUnitOfMeasureToProducts < ActiveRecord::Migration[8.0]
  def up
    # Ensure Unidad exists (should already exist from units migration, but safe to check)
    unidad = execute("SELECT id FROM unit_of_measures WHERE name = 'Unidad'").first
    raise "Unidad unit_of_measure must exist before running this migration" unless unidad
    unidad_id = unidad['id']

    add_reference :products, :unit_of_measure, foreign_key: true, null: true

    # Assign Unidad to all existing products
    execute <<-SQL
      UPDATE products SET unit_of_measure_id = #{unidad_id}
    SQL

    # Enforce NOT NULL
    change_column_null :products, :unit_of_measure_id, false
  end

  def down
    remove_reference :products, :unit_of_measure
  end
end
