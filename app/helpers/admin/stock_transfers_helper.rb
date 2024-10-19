module Admin::StockTransfersHelper
  def determine_action_if_in_transit(stock_transfer)
    if stock_transfer.destination_warehouse_id == @current_warehouse.id
      link_to "Recibir Transferencia", initiate_receive_admin_stock_transfer_path(stock_transfer), data: { turbo_method: :get }, remote: true, class: "btn btn-primary"
    else
      "Por Recibir en Destino"
    end
  end
end
