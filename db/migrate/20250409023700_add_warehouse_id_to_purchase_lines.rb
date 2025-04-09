class AddWarehouseIdToPurchaseLines < ActiveRecord::Migration[8.0]
  def change
    add_reference :purchases_purchase_lines, :warehouse, foreign_key: true
  end
end
