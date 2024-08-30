class CreateCashInflows < ActiveRecord::Migration[7.2]
  def change
    create_table :cash_inflows do |t|
      t.references :cashier_shift, null: false, foreign_key: true, index: true
      t.references :received_by, null: false, foreign_key: { to_table: :users }, index: true
      t.string :custom_id, null: false
      t.text :description, null: false
      t.integer :cash_inflow_type, default: 0, null: false
      t.integer :amount_cents, null: false
      t.string :currency, default: "PEN", null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :cash_inflows, :custom_id, unique: true
    add_index :cash_inflows, :cash_inflow_type
  end
end
