class Admin::OrdersController < Admin::AdminController
  include MoneyRails::ActionViewExtension
  include CurrencyFormattable
  include AdminHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper  # For link_to
  include ActionView::Context
  include ActionView::Helpers::FormTagHelper  # For button_tag
  include ActionView::Helpers::FormOptionsHelper

  before_action :check_duplicate_order, only: [ :create ]

  def index
    respond_to do |format|
      format.html do
        @orders = if @current_location
          Order.includes([ :invoices, :external_invoices, :location ])
              .where(location_id: @current_location.id)
              .with_commission_status
              .order(id: :desc)
              .limit(10)
        else
          Order.includes([ :invoices, :location, :external_invoices ])
              .with_commission_status
              .order(id: :desc)
              .limit(10)
        end
        @datatable_options = "server_side:true;resource_name:'Order';create_button:false;sort_0_desc;hide_0;"
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
      @order.total_original_price = @order.total_price if @order.total_original_price.blank?

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
        credit_payment_method = PaymentMethod.find_by(name: "credit")
        if order_params[:payments_attributes]
          order_params[:payments_attributes].each do |payment|
            @order.payments.create!(
              payment.merge(
                payment_date: @order.order_date,
                payable: @order,
                cashier_shift: @order.determine_cashier_shift_based_on_order_date(@current_cashier, @current_cashier_shift),
                status: @order.origin == "pos" && (payment[:payment_method_id]&.to_i != credit_payment_method&.id) ? "paid" : "pending"
              )
            )
          end
          Services::Sales::PaymentAdjustmentService.new(@order).adjust_payments
        end
        if order_params[:sellers_attributes].present?
          Services::Sales::OrderCommissionService.new(@order).calculate_and_save_commissions(order_params[:sellers_attributes])
        end
        if @order.fast_stock_transfer_flag
          Services::Inventory::OrderItemService.new(@order).update_inventory
        end
        GenerateEinvoice.perform_async(@order.id) if ENV["RAILS_ENV"] == "production"

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
    authorize! :create, Order
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
    @order = Order.includes(:commissions).find(params[:id])
    render :edit
  end

  def update
    @order = Order.find(params[:id])

    if params[:order][:commissions_attributes].present?
      # Handle commission updates
      if Services::Sales::OrderCommissionService.new(@order).calculate_and_save_commissions(
        params[:order][:commissions_attributes]&.values || []
      )
        redirect_to admin_order_path(@order), notice: "Comisiones actualizadas exitosamente."
      else
        flash.now[:error] = "Error al actualizar las comisiones."
        render :edit_commissions, status: :unprocessable_entity
      end
    else
      # Handle regular order updates
      service = Services::Sales::OrderItemEditService.new(@order)

      # Transform the nested attributes to use order_item IDs as keys
      # and convert prices to cents
      transformed_params = {}
      order_params[:order_items_attributes].each do |_, item_attrs|
        transformed_params[item_attrs[:id]] = {
          id: item_attrs[:id],
          product_id: item_attrs[:product_id],
          quantity: item_attrs[:quantity],
          price_cents: (item_attrs[:price].to_f * 100).to_i
        }
      end

      if service.update_order_items(transformed_params)
        redirect_to admin_order_path(@order), notice: "Venta actualizada exitosamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def void
    @order = Order.find(params[:id])
    result = Services::Sales::OrderVoidService.new(@order, current_user).void
    if result[0] == true
      redirect_to admin_orders_path, notice: "Venta anulada exitosamente."
    else
      redirect_to admin_orders_path, alert: "Error al anular la venta: #{result[1]}"
    end
  end

  def edit_payments
    authorize! :manage, Payment
    @order = Order.includes(payments: :payment_method).find(params[:id])
  end

  def update_payments
    @order = Order.find(params[:id])

    begin
      Services::Sales::OrderPaymentEditService.update_payments(@order, order_params[:payments_attributes], @current_cashier, @current_cashier_shift)
      @order.reevaluate_payment_status

      respond_to do |format|
        format.turbo_stream {
          redirect_to admin_order_path(@order), notice: "Pagos actualizados exitosamente"
        }
        format.html { redirect_to admin_order_path(@order), notice: "Pagos actualizados exitosamente" }
      end
    rescue => e
      respond_to do |format|
        format.turbo_stream {
          flash[:alert] = "Error al actualizar pagos: #{e.message}"
          redirect_to edit_payments_admin_order_path(@order)
        }
        format.html {
          flash[:alert] = "Error al actualizar pagos: #{e.message}"
          redirect_to edit_payments_admin_order_path(@order)
        }
      end
    end
  end

  def edit_commissions
    @order = Order.includes(:commissions).find(params[:id])
    render :edit_commissions
  end

  def update_commissions
    @order = Order.includes(commissions: :user).find(params[:id])

    # Filter out any empty or zero percentage commissions
    filtered_params = order_params
    if filtered_params[:commissions_attributes].present?
      filtered_params[:commissions_attributes].reject! do |_, commission|
        commission[:percentage].to_f.zero? || commission[:user_id].blank?
      end
    end

    if Services::Sales::OrderCommissionService.new(@order).calculate_and_save_commissions(
      filtered_params[:commissions_attributes]&.values || []
    )
      redirect_to admin_order_path(@order), notice: "Comisiones actualizadas exitosamente."
    else
      flash.now[:error] = "Error al actualizar las comisiones."
      render :edit_commissions, status: :unprocessable_entity
    end
  end

  private

    def order_params
      params.require(:order).permit(
        :region_id, :user_id, :origin, :order_recipient_id, :location_id, :total_price, :total_discount, :total_original_price, :shipping_price, :currency, :wants_factura, :stage, :payment_status, :cart_id, :shipping_address_id, :billing_address_id, :coupon_applied, :customer_note, :seller_note, :active_invoice_id, :invoice_id_required, :order_date, :request_id, :preorder_id, :fast_payment_flag, :fast_stock_transfer_flag, :is_credit_sale, :price_list_id, :nota_de_venta,
        order_items_attributes: [ :id, :order_id, :product_id, :quantity, :price, :price_cents, :discounted_price, :discounted_price_cents, :currency, :is_loyalty_free, :birthday_discount, :birthday_image, :product_pack_id ],
        payments_attributes: [ :id, :user_id, :payment_method_id, :amount, :amount_cents, :currency, :payable_type, :processor_transacion_id, :due_date, :_destroy ],
        sellers_attributes: [ :id, :user_id, :percentage, :amount ],
        commissions_attributes: [ :id, :percentage, :amount_cents, :sale_amount_cents, :sale_amount, :currency, :status, :user_id, :order_id ])
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
      orders = if @current_location
        Order.includes([ :user, :invoices, :external_invoices, :location ])
            .where(location_id: @current_location.id)
            .with_commission_status
      else
        Order.includes([ :user, :invoices, :location, :external_invoices ])
            .with_commission_status
      end

      # Apply search filter
      if params[:search][:value].present?
        orders = orders.search_by_customer_name_or_total_or_invoice_number(params[:search][:value])
      end

      # Apply sorting
      if params[:order].present?
        column_index = params[:order]["0"][:column].to_i
        direction = params[:order]["0"][:dir]

        case column_index
        when 0
          orders = orders.reorder(Arel.sql("orders.id #{direction}"))
        when 1
          if current_user.any_admin_or_supervisor?
            orders = orders.joins(:location).reorder(Arel.sql("locations.name #{direction}"))
          end
        when 2
          orders = orders.reorder(Arel.sql("orders.custom_id #{direction}"))
        when 3
          orders = orders.reorder(Arel.sql("orders.order_date #{direction}"))
        when 4
          orders = orders.joins(:user)
                        .reorder(Arel.sql("users.first_name #{direction}, users.last_name #{direction}"))
        when 5
          orders = orders.reorder(Arel.sql("orders.total_price_cents #{direction}"))
        when 6
          orders = orders.reorder(Arel.sql("orders.total_original_price_cents #{direction}"))
        when 7
          orders = orders.reorder(Arel.sql("orders.total_discount_cents #{direction}"))
        when 10
          orders = orders.reorder(Arel.sql("orders.payment_status #{direction}"))
        when 11
          orders = orders.reorder(Arel.sql("orders.stage #{direction}"))
        else
          orders = orders.reorder(id: :desc)
        end
      else
        orders = orders.order(id: :desc) # Default sorting
      end

      # Pagination
      orders = orders.page(params[:start].to_i / params[:length].to_i + 1).per(params[:length].to_i)

      {
        draw: params[:draw].to_i,
        recordsTotal: Order.count,
        recordsFiltered: orders.total_count,
        data: orders.map do |order|
          row = [
            order.id
          ]

          if current_user.any_admin_or_supervisor?
            row << order.location&.name
          end

          row.concat([
            order.custom_id,
            friendly_date(current_user, order.order_date),
            order&.user&.name,
            format_currency(order.total_price),
            format_currency(order.total_original_price),
            format_currency(order.total_discount),
            show_invoice_actions(order, "pdf"),
            show_invoice_actions(order, "xml"),
            order.translated_payment_status,
            order.translated_status
          ])

          # Only include the commission status column if the feature flag is enabled
          if $global_settings[:feature_flag_sales_attributed_to_seller]
            row << (order.missing_commission ? helpers.content_tag(:span, "Sin comisión", class: "inline-flex items-center rounded-md bg-red-50 px-2 py-1 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/10 dark:bg-red-900/20 dark:text-red-400 dark:ring-red-500/20") : "")
          end

          row << render_to_string(
            partial: "admin/orders/view_action",
            formats: [ :html ],
            locals: { order: order }
          )

          if current_user.any_admin_or_supervisor?
            row << render_to_string(
              partial: "admin/orders/edit_action",
              formats: [ :html ],
              locals: { order: order }
            )
          end

          # Add void action column - always include it but conditionally show content
          row << if current_user.any_admin_or_supervisor? || ($global_settings[:feature_flag_sellers_can_void_orders] && order.created_at > 7.days.ago)
            render_to_string(
              partial: "admin/orders/void_action",
              formats: [ :html ],
              locals: { order: order, current_user: current_user }
            )
          else
            # Empty string for users without permission
            ""
          end

          row
        end
      }
    end

    def check_duplicate_order
      return unless params[:request_id]

      # Check for recent orders with the same request_id
      recent_duplicate = Order.where(request_id: params[:request_id])
                            .where("created_at > ?", 1.minute.ago)
                            .first

      if recent_duplicate
        render json: {
          status: "error",
          errors: [ "Esta orden ya fue procesada." ],
          duplicate: true,
          original_order_id: recent_duplicate.id
        }, status: :unprocessable_entity
        nil
      end
    end
end
