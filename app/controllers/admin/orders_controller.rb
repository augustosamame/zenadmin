class Admin::OrdersController < Admin::AdminController
  include MoneyRails::ActionViewExtension

  def index
    respond_to do |format|
      format.html do
        if current_user.any_admin_or_supervisor?
          @orders = Order.all
        else
          @orders = Order.where(location_id: @current_location.id)
        end
        if @orders.size > 500
          @datatable_options = "server_side:true;resource_name:'Order';create_button:false;sort_0_desc;"
        else
          @datatable_options = "server_side:false;resource_name:'Order';create_button:false;sort_0_desc;"
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
      @order.total_original_price = @order.total_price

      if @order.origin == "pos"
        # POS context: current_user is the seller, user_id is provided
        @order.seller_id = current_user.id
        if @order.user_id.blank?
          @order.user_id = User.find(get_generic_customer_id)&.id
        else
          # id passed is actually the customer id
          @order.user_id = Customer.find(@order.user_id)&.user_id
        end
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
        Services::Inventory::OrderItemService.new(@order).update_inventory
        GenerateEinvoice.perform_async(@order.id)

        session.delete(:draft_order)
        render json: { status: "success", id: @order.id, message: "Order created successfully.", universal_invoice_link: @order.universal_invoice_link, order_data: @order.as_json(include: [ :user ]) }
      else
        Rails.logger.info("Error creating order: #{@order.errors.full_messages}")
        render json: { status: "error", errors: @order.errors.full_messages }
      end
    end
  rescue ActiveRecord::Rollback => e
    Rails.logger.info("Error creating order in rollback: #{@order.errors.full_messages}")
    render json: { status: "error", errors: e.message }
  end

  def show
    @order = Order.includes(payments: :payment_method, commissions: :user).find(params[:id])
  end

  def pos
    @order = Order.new
    @can_create_unpaid_orders = $global_settings[:pos_can_create_unpaid_orders]
    if @current_cashier_shift.blank? || @current_cashier_shift.status == "closed"
      redirect_to admin_cashier_shifts_path, alert: "El turno de caja está cerrado."
    end
  end

  def retry_invoice
    @order = Order.find(params[:order_id])
    @options = {}

    # don't use worker here so we can get the response back to the frontend
    Services::Sales::OrderInvoiceService.new(@order, @options).create_invoices

    respond_to do |format|
      format.html do
        redirect_to admin_orders_path, notice: "Se ha reenviado el comprobante."
      end
      format.json do
        render json: { message: "Se ha reenviado el comprobante.", success: true }, status: :ok
      end
    end
  end

  def edit
    @order = Order.includes(commissions: :user).find(params[:id])
    @commissions = @order.commissions
  end

  def update
    @order = Order.includes(commissions: :user).find(params[:id])
    if @order.update(order_params)
      Services::Sales::OrderCommissionService.new(@order).recalculate_commissions
      redirect_to admin_order_path(@order), notice: "Comisiones actualizadas exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

    def order_params
      params.require(:order).permit(:region_id, :user_id, :origin, :order_recipient_id, :location_id, :total_price, :total_discount, :shipping_price, :currency, :wants_factura, :stage, :payment_status, :cart_id, :shipping_address_id, :billing_address_id, :coupon_applied, :customer_note, :seller_note, :active_invoice_id, :invoice_id_required, :order_date, order_items_attributes: [ :order_id, :product_id, :quantity, :price, :price_cents, :discounted_price, :discounted_price_cents, :currency, :is_loyalty_free ], payments_attributes: [ :user_id, :payment_method_id, :amount, :amount_cents, :currency, :payable_type ], sellers_attributes: [ :id, :percentage ], commissions_attributes: [ :id, :percentage, :amount_cents, :sale_amount_cents, :currency, :status, :user_id, :order_id ])
    end

    def get_generic_customer_id
      # Logic to find the generic customer (guest)
      User.find_by!(email: "generic_customer@devtechperu.com")&.id
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
            format_currency(order.total_price),
            format_currency(order.total_discount),
            order.active_invoice_id,
            order.payment_status,
            order.status,
            render_to_string(partial: "admin/orders/actions", formats: [ :html ], locals: { order: order, default_object_options_array: @default_object_options_array })
          ]
        end
      }
    end
end
