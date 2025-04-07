class AddTransportistaIdToStockTransfers < ActiveRecord::Migration[8.0]
  def change
    add_reference :stock_transfers, :transportista, null: true, foreign_key: true
  end
end
