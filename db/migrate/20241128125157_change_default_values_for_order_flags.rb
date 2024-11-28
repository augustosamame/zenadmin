class ChangeDefaultValuesForOrderFlags < ActiveRecord::Migration[7.2]
  def up
    change_column_default :orders, :fast_stock_transfer_flag, from: false, to: true
    change_column_default :orders, :fast_payment_flag, from: false, to: true
  end

  def down
    change_column_default :orders, :fast_stock_transfer_flag, from: true, to: false
    change_column_default :orders, :fast_payment_flag, from: true, to: false
  end
end
