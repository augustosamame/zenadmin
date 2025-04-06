class Admin::VoidedOrdersController <  Admin::AdminController
  def index
    if @current_location
      @voided_orders = VoidedOrder.includes(:location, :user)
                                 .where(location_id: @current_location.id)
                                 .order(created_at: :desc)
                                 .page(params[:page])
                                 .per(25)
    else
      @voided_orders = VoidedOrder.includes(:location, :user)
                                 .order(created_at: :desc)
                                 .page(params[:page])
                                 .per(25)
    end
  end

  def show
    @voided_order = VoidedOrder.find(params[:id])
    @order_data = @voided_order.original_order_data
  end
end
