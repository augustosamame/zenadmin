class MakePaymentPayableOptional < ActiveRecord::Migration[7.1]
  def change
    change_column_null :payments, :payable_type, true
    change_column_null :payments, :payable_id, true
  end
end
