class AddRealStockToPeriodicInventoryLines < ActiveRecord::Migration[7.2]
  def change
    add_column :periodic_inventory_lines, :real_stock, :integer, default: 0
  end
end
