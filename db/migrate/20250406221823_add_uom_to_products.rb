class AddUomToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :unit_of_measure, :string, default: "NIU"
  end
end
