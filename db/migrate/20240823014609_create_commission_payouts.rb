class CreateCommissionPayouts < ActiveRecord::Migration[7.2]
  def change
    create_table :commission_payouts do |t|
      t.references :commission, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string :amount_currency, default: "PEN"
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
