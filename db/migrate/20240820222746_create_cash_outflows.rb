class CreateCashOutflows < ActiveRecord::Migration[7.2]
  def change
    create_table :cash_outflows do |t|
      t.references :cashier_shift, null: false, foreign_key: true, index: true
      t.references :paid_to, null: false, foreign_key: { to_table: :users }, index: true
      t.string :custom_id, null: false
      t.text :description, null: false
      t.integer :cash_outflow_type, default: 0, null: false
      t.integer :amount_cents, null: false
      t.string :currency, default: "PEN", null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :cash_outflows, :custom_id, unique: true
    add_index :cash_outflows, :cash_outflow_type
  end
end
