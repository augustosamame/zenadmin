module Admin::StockTransfersHelper
  def determine_action_if_in_transit(stock_transfer)
    if stock_transfer.destination_warehouse_id == @current_warehouse.id
      link_to "Recibir Transferencia", initiate_receive_admin_stock_transfer_path(stock_transfer), data: { turbo_method: :get }, remote: true, class: "btn btn-primary"
    else
      "Por Recibir en Destino"
    end
  end

  def determine_action_if_pending(stock_transfer)
    if $global_settings[:stock_transfers_have_in_transit_step]
      if stock_transfer.origin_warehouse_id == @current_warehouse.id
        link_to "Entregar a Transportista", set_to_in_transit_admin_stock_transfer_path(stock_transfer), data: { turbo_method: :patch }, class: "btn btn-secondary"
      else
        "Por Entregar a Transportista en Origen"
      end
    else
      if stock_transfer.origin_warehouse_id == @current_warehouse.id
        link_to "Entregar a Destino", initiate_receive_admin_stock_transfer_path(stock_transfer), data: { turbo_method: :get }, remote: true, class: "btn btn-primary"
      else
        "Pendiente en Origen"
      end
    end
  end

  def translated_stage(stage)
    case stage
    when "pending"
      "Pendiente"
    when "in_transit"
      "En Tránsito"
    when "complete"
      "Completado"
    end
  end
end
