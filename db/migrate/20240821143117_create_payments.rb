class CreatePayments < ActiveRecord::Migration[7.2]
  def change
    create_table :payments do |t|
      t.references :payment_method, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :region, null: false, foreign_key: true
      t.references :payable, polymorphic: true, null: false
      t.references :cashier_shift, null: false, foreign_key: true
      t.integer :payment_request_id
      t.integer :processor_transacion_id
      t.integer :amount_cents, null: false
      t.string :currency, default: "PEN"
      t.datetime :payment_date, null: false
      t.text :comment
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
