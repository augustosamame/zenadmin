class AddUnitPriceToPurchaseLines < ActiveRecord::Migration[8.0]
  def change
    # Remove the old price column
    remove_column :purchases_purchase_lines, :price, :decimal, precision: 10, scale: 2
    
    # Add the money-rails columns
    add_column :purchases_purchase_lines, :unit_price_cents, :integer, default: 0, null: false
    add_column :purchases_purchase_lines, :unit_price_currency, :string, default: "PEN", null: false
  end
end
