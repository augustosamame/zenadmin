class MakeStockTransferOptionalInGuias < ActiveRecord::Migration[8.0]
  def change
    change_column_null :guias, :stock_transfer_id, true
  end
end
