class CreateCashierShifts < ActiveRecord::Migration[7.2]
  def change
    create_table :cashier_shifts do |t|
      t.references :cashier, null: false, foreign_key: true
      t.date :date, null: false
      t.integer :total_sales_cents
      t.datetime :opened_at, null: false
      t.datetime :closed_at
      t.references :opened_by, null: false, foreign_key: { to_table: 'users' }
      t.references :closed_by, foreign_key: { to_table: 'users' }
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
