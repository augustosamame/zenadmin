class Admin::WarehousesController < Admin::AdminController
  def set_current_warehouse
    warehouse_id = params[:id]

    warehouse = Warehouse.find_by(id: warehouse_id)
    if warehouse
      session[:current_warehouse_id] = warehouse_id
      @current_warehouse = warehouse
      render json: { success: true }, status: :ok
    else
      render json: { success: false, message: "Warehouse not found" }, status: :not_found
    end
  end
end
