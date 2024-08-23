class CreateCommissions < ActiveRecord::Migration[7.2]
  def change
    create_table :commissions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string :currency, default: "PEN"
      t.integer :percentage, null: false
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
