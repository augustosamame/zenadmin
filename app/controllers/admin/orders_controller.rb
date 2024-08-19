class Admin::OrdersController < Admin::AdminController
  include ActionView::Helpers::NumberHelper

  def new
    @order_data = session[:draft_order] || {}
  end

  def create
    # TODO - Add validations for order creation for things that may have been changed in the frontend. Like max discount, etc. Maybe do this in the model?
    @order = Order.new(order_params)
    if @order.save
      session.delete(:draft_order) # Clear the draft after saving the order
      render json: { status: "success", id: @order.id, message: "Order created successfully." }
    else
      render json: { status: "error", errors: @order.errors.full_messages }
    end
  end

  def pos
    @order = Order.new
  end

  private

  def order_params
    params.require(:order).permit(:region_id, :user_id, :order_recipient_id, :location_id, :total_price, :total_discount, :shipping_price, :currency, :cart_id, :shipping_address_id, :billing_address_id, :coupon_applied, :customer_note, :seller_note, :active_invoice_id, :invoice_id_required, :order_date, order_items_attributes: [ :order_id, :product_id, :quantity, :price, :discounted_price, :currency ])
  end
end
