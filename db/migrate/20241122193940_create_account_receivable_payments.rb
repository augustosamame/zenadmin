class CreateAccountReceivablePayments < ActiveRecord::Migration[7.2]
  def change
    create_table :account_receivable_payments do |t|
      t.references :account_receivable, null: false, foreign_key: true
      t.references :payment, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "PEN"
      t.text :notes
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
