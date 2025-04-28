class AddServicioTransporteHashToOrder < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :servicio_transporte_hash, :jsonb, default: {}, null: false
  end
end
