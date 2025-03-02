class AddPriceListToCustomers < ActiveRecord::Migration[7.2]
  def change
    add_reference :customers, :price_list, null: true, foreign_key: true
  end
end
