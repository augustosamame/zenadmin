class AddServicioTransporteFlagToOrder < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :servicio_transporte, :boolean, default: false
    add_index :orders, :servicio_transporte
  end
end
