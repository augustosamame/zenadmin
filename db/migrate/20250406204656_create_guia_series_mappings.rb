class CreateGuiaSeriesMappings < ActiveRecord::Migration[8.0]
  def change
    create_table :guia_series_mappings do |t|
      t.references :guia_series, null: false, foreign_key: true
      t.references :location, null: false, foreign_key: true
      t.boolean :default, default: false

      t.timestamps
    end
  end
end
