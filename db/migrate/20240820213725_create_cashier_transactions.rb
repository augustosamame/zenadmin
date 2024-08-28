class CreateCashierTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :cashier_transactions do |t|
      t.references :cashier_shift, null: false, foreign_key: true
      t.references :transactable, polymorphic: true, null: false
      t.integer :transaction_type, default: 0, null: false
      t.integer :amount_cents, null: false
      t.string :currency, default: "PEN", null: false

      t.timestamps
    end
  end
end
