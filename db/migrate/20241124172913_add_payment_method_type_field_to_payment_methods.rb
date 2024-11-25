class AddPaymentMethodTypeFieldToPaymentMethods < ActiveRecord::Migration[7.2]
  def change
    add_column :payment_methods, :payment_method_type, :integer, default: 0
    add_column :payment_methods, :cashier_name, :string
    add_index :payment_methods, :payment_method_type
    add_column :cashier_transactions, :processor_transacion_id, :string
    add_index :cashier_transactions, :processor_transacion_id
    add_column :cashiers, :cashier_type, :integer, default: 0
    add_index :cashiers, :cashier_type
    add_column :cash_inflows, :processor_transacion_id, :string
    add_index :cash_inflows, :processor_transacion_id
    add_column :cash_outflows, :processor_transacion_id, :string
    add_index :cash_outflows, :processor_transacion_id
  end
end
