class MakeOrderIdAndPaymentIdNullableInAccountReceivables < ActiveRecord::Migration[7.2]
  def change
    change_column_null :account_receivables, :order_id, true
    change_column_null :account_receivables, :payment_id, true
  end
end
