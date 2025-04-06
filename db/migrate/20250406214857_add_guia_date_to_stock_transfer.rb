class AddGuiaDateToStockTransfer < ActiveRecord::Migration[8.0]
  def change
    add_column :stock_transfers, :date_guia, :datetime
  end
end
