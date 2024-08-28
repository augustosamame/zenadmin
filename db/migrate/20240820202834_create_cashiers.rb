class CreateCashiers < ActiveRecord::Migration[7.2]
  def change
    create_table :cashiers do |t|
      t.references :location, null: false, foreign_key: true
      t.string :name, null: false, default: "Caja Principal"
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
