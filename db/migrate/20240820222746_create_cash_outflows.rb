class CreateCashOutflows < ActiveRecord::Migration[7.2]
  def change
    create_table :cash_outflows do |t|
      t.references :cashier_shift, null: false, foreign_key: true
      t.references :paid_to, null: false, foreign_key: { to_table: :users }
      t.text :description, null: false
      t.integer :cash_outflow_type, default: 0, null: false
      t.integer :amount_cents, null: false
      t.string :currency, default: "PEN", null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
