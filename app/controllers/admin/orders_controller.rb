class Admin::OrdersController < Admin::AdminController
  include ActionView::Helpers::NumberHelper

  def index
    respond_to do |format|
      format.html do
        @orders = Order.includes([ :user ]).all
        if @orders.size > 50
          @datatable_options = "server_side:true;resource_name:'Order';create_button:false;"
        else
          @datatable_options = "server_side:false;resource_name:'Order';create_button:false;"
        end
      end

      format.json do
        render json: datatable_json
      end
    end
	end

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
        @order.location_id = @current_location.id
      elsif @order.origin == "ecommerce"
        # eCommerce context: current_user is the eCommerce store, user_id is not provided
        @order.user_id = current_user.id
        @order.seller_id = get_ecommerce_store_seller_id
        @order.location_id = @current_location.id
      end

      if @order.save!
        if order_params[:payments_attributes]
          order_params[:payments_attributes].each do |payment|
            @order.payments.create!(payment.merge(payable: @order, cashier_shift: @current_cashier_shift))
          end
        end
        if order_params[:sellers_attributes].present?
          Services::Sales::OrderCommissionService.new(@order).calculate_and_save_commissions(order_params[:sellers_attributes])
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
    @can_create_unpaid_orders = $global_settings[:pos_can_create_unpaid_orders]
    if @current_cashier_shift.blank? || @current_cashier_shift.status == "closed"
      redirect_to admin_cashier_shifts_path, alert: "El turno de caja está cerrado."
    end
  end

  private

    def order_params
      params.require(:order).permit(:region_id, :user_id, :origin, :order_recipient_id, :location_id, :total_price, :total_discount, :shipping_price, :currency, :stage, :payment_status, :cart_id, :shipping_address_id, :billing_address_id, :coupon_applied, :customer_note, :seller_note, :active_invoice_id, :invoice_id_required, :order_date, order_items_attributes: [ :order_id, :product_id, :quantity, :price, :discounted_price, :currency ], payments_attributes: [ :user_id, :payment_method_id, :amount, :currency, :payable_type ], sellers_attributes: [ :id, :percentage ])
    end

    def get_generic_customer_id
      # Logic to find the generic customer (guest)
      User.find_by!(email: "generic_customer@devtechperu.com").try(:id)
    end

    def get_ecommerce_store_seller_id
      # Logic to find the appropriate seller ID for the eCommerce store
      User.find_by!(email: "ecommerce@devtechperu.com").try(:id)
    end

    def datatable_json
      orders = Order.all

      # Apply search filter
      if params[:search][:value].present?
        orders = orders.search_by_customer_name(params[:search][:value])
      end

      # Apply sorting
      if params[:order].present?
        order_by = case params[:order]["0"][:column].to_i
        when 0 then "id"
        when 1 then "order_date"
        when 2
          # For the customer column, join the users table and order by first_name
          orders = orders.joins(:user)
          "users.first_name, users.last_name"
        when 3 then "total_price_cents"
        when 4 then "total_discount_cents"
        when 6 then "payment_status"
        when 7 then "status"
        else "id"
        end
        direction = params[:order]["0"][:dir] == "desc" ? "desc" : "asc"
        orders = orders.reorder("#{order_by} #{direction}")
      end

      # Pagination
      orders = orders.page(params[:start].to_i / params[:length].to_i + 1).per(params[:length].to_i)
      # Return the data in the format expected by DataTables
      {
        draw: params[:draw].to_i,
        recordsTotal: Order.count,
        recordsFiltered: orders.total_count,
        data: orders.map do |order|
          [
            order.id,
            order.order_date&.strftime("%Y-%m-%d %H:%M:%S"),
            order.customer.name,
            number_to_currency(order.total_price, unit: "S/"),
            number_to_currency(order.total_discount, unit: "S/"),
            order.active_invoice_id,
            order.payment_status,
            order.status,
            render_to_string(partial: "admin/orders/actions", formats: [ :html ], locals: { order: order, default_object_options_array: @default_object_options_array })
          ]
        end
      }
    end
end
