class Admin::VoidedOrdersController <  Admin::AdminController
  def index
    @voided_orders = VoidedOrder.includes(:location, :user)
                               .order(created_at: :desc)
                               .page(params[:page])
  end

  def show
    @voided_order = VoidedOrder.find(params[:id])
    @order_data = @voided_order.original_order_data
  end
end
