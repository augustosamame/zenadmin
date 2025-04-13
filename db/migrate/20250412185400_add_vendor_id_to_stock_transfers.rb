class AddVendorIdToStockTransfers < ActiveRecord::Migration[7.0]
  def change
    add_reference :stock_transfers, :vendor, foreign_key: { to_table: :purchases_vendors }, null: true
  end
end
