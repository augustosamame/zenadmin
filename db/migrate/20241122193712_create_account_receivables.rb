class CreateAccountReceivables < ActiveRecord::Migration[7.2]
  def change
    create_table :account_receivables do |t|
      t.references :user, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.references :payment, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "PEN"
      t.datetime :due_date
      t.text :notes
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
