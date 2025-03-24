class AddPlannedStockTransferToStockTransfer < ActiveRecord::Migration[8.0]
  def change
    add_reference :stock_transfers, :planned_stock_transfer, null: true, foreign_key: true, index: true
  end
end
