class Admin::OrdersController < Admin::AdminController
  include ActionView::Helpers::NumberHelper

  def new
    @order_data = session[:draft_order] || {}
  end

  def create
    ActiveRecord::Base.transaction do
      # TODO - Add validations for order creation for things that may have been changed in the frontend. Like max discount, etc. Maybe do this in the model?
      @order = Order.new(order_params.except(:payments_attributes))

      if @order.origin == "pos"
        # POS context: current_user is the seller, user_id is provided
        @order.seller_id = current_user.id
        @order.user_id ||= get_generic_customer_id
      elsif @order.origin == "ecommerce"
        # eCommerce context: current_user is the eCommerce store, user_id is not provided
        @order.user_id = current_user.id
        @order.seller_id = get_ecommerce_store_seller_id
      end

      if @order.save
        if order_params[:payments_attributes]
          order_params[:payments_attributes].each do |payment|
            @order.payments.create(payment.merge(payable: @order))
          end
        end

        session.delete(:draft_order)
        render json: { status: "success", id: @order.id, message: "Order created successfully." }
      else
        render json: { status: "error", errors: @order.errors.full_messages }
      end
    end
    rescue ActiveRecord::Rollback => e
      render json: { status: "error", errors: e.message }
  end

  def pos
    @order = Order.new
  end

  private

  def order_params
    params.require(:order).permit(:region_id, :user_id, :origin, :order_recipient_id, :location_id, :total_price, :total_discount, :shipping_price, :currency, :stage, :payment_status, :cart_id, :shipping_address_id, :billing_address_id, :coupon_applied, :customer_note, :seller_note, :active_invoice_id, :invoice_id_required, :order_date, order_items_attributes: [ :order_id, :product_id, :quantity, :price, :discounted_price, :currency ], payments_attributes: [ :user_id, :payment_method_id, :amount, :currency, :payable_type ])
  end

  def get_generic_customer_id
    # Logic to find the generic customer (guest)
    User.find_by!(email: "generic_customer@devtechperu.com").try(:id)
  end

  def get_ecommerce_store_seller_id
    # Logic to find the appropriate seller ID for the eCommerce store
    User.find_by!(email: "ecommerce@devtechperu.com").try(:id)
  end
end
