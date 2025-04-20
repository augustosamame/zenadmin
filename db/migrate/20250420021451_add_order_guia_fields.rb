class AddOrderGuiaFields < ActiveRecord::Migration[8.0]
  def change
    add_reference :guias, :order, foreign_key: true, null: true
    add_reference :orders, :transportista, foreign_key: true, null: true
    add_column :locations, :ubigeo, :string
  end
end
