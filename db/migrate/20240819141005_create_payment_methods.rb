class CreatePaymentMethods < ActiveRecord::Migration[7.2]
  def change
    create_table :payment_methods do |t|
      t.string :name, null: false
      t.string :description, null: false
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
