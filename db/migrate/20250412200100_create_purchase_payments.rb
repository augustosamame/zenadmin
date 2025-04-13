class CreatePurchasePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_payments do |t|
      t.references :payment_method, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :region, null: false, foreign_key: true
      t.references :payable, polymorphic: true, index: true
      t.references :cashier_shift, foreign_key: true
      t.references :original_payment, foreign_key: { to_table: :purchase_payments }
      t.references :purchase_invoice, foreign_key: true
      t.references :vendor, foreign_key: { to_table: :purchases_vendors }, null: true

      t.string :custom_id
      t.integer :amount_cents, default: 0, null: false
      t.string :currency
      t.datetime :payment_date
      t.text :comment
      t.integer :status, default: 0
      t.string :processor_transacion_id
      t.datetime :due_date
      t.string :description

      t.timestamps
    end
  end
end
