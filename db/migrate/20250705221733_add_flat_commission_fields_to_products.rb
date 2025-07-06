class AddFlatCommissionFieldsToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :flat_commission, :boolean, default: false
    add_column :products, :flat_commission_percentage, :decimal, precision: 10, scale: 2
  end
end
