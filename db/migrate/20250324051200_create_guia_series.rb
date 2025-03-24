class CreateGuiaSeries < ActiveRecord::Migration[8.0]
  def change
    create_table :guia_series do |t|
      t.references :invoicer, null: false, foreign_key: true
      t.string :prefix, null: false
      t.integer :next_number, default: 1, null: false
      t.integer :guia_type, default: 0, null: false
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
