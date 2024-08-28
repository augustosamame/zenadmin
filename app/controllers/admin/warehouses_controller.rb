class Admin::WarehousesController < Admin::AdminController

  def set_current_warehouse
    warehouse_id = params[:id]

    if Warehouse.exists?(warehouse_id)
      session[:current_warehouse_id] = warehouse_id
      @current_warehouse = Warehouse.find(warehouse_id)
      render json: { success: true }, status: :ok
    else
      render json: { success: false, message: "Warehouse not found" }, status: :not_found
    end
  end
  
end