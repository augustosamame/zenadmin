class CreatePayments < ActiveRecord::Migration[7.2]
  def change
    create_table :payments do |t|
      t.references :payment_method, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true
      t.references :region, null: false, foreign_key: true, index: true
      t.references :payable, polymorphic: true, null: false
      t.references :cashier_shift, null: false, foreign_key: true, index: true
      t.string :custom_id, null: false
      t.integer :payment_request_id
      t.integer :processor_transacion_id
      t.integer :amount_cents, null: false
      t.string :currency, default: "PEN"
      t.datetime :payment_date, null: false
      t.text :comment
      t.integer :status, default: 0

      t.timestamps
    end

    add_index :payments, :custom_id, unique: true
    add_index :payments, :payment_request_id
    add_index :payments, :payment_date
    add_index :payments, :status
  end
end
