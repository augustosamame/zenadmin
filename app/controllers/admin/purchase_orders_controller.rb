class Admin::PurchaseOrdersController < Admin::AdminController
  include MoneyRails::ActionViewExtension
  include CurrencyFormattable
  include AdminHelper

  before_action :set_purchase_order, only: [ :show, :edit, :update, :create_purchase ]

  def index
    respond_to do |format|
      format.html do
        @purchase_orders = Purchases::PurchaseOrder.includes(:vendor, :user)
                                                  .order(created_at: :desc)
                                                  .limit(10)
        @datatable_options = "server_side:true;resource_name:'PurchaseOrder';sort_0_desc;hide_0;create_button:true;"
      end

      format.json do
        render json: datatable_json
      end
    end
  end

  def new
    @purchase_order = Purchases::PurchaseOrder.new
    @purchase_order.purchase_order_lines.build
  end

  def create
    @purchase_order = Purchases::PurchaseOrder.new(purchase_order_params)
    @purchase_order.user_id = current_user.id
    # Only set region_id if @current_region exists
    @purchase_order.region_id = @current_region.id if @current_region.present?

    respond_to do |format|
      if @purchase_order.save
        format.html { redirect_to admin_purchase_order_path(@purchase_order), notice: "Purchase order was successfully created." }
        format.json { render :show, status: :created, location: @purchase_order }
      else
        format.html { render :new }
        format.json { render json: @purchase_order.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
  end

  def edit
  end

  def update
    respond_to do |format|
      if @purchase_order.update(purchase_order_params)
        format.html { redirect_to admin_purchase_order_path(@purchase_order), notice: "Purchase order was successfully updated." }
        format.json { render :show, status: :ok, location: @purchase_order }
      else
        format.html { render :edit }
        format.json { render json: @purchase_order.errors, status: :unprocessable_entity }
      end
    end
  end

  def create_purchase
    respond_to do |format|
      if @purchase_order.purchase.present?
        format.html { redirect_to admin_purchase_order_path(@purchase_order), alert: "Purchase already exists for this order." }
      else
        purchase = @purchase_order.create_purchase(current_user.id)

        if purchase.persisted?
          # Update inventory
          Services::Inventory::PurchaseItemService.new(purchase).update_inventory

          # Update purchase order status
          @purchase_order.update(status: "completed")

          format.html { redirect_to admin_purchase_path(purchase), notice: "Purchase was successfully created from order." }
        else
          format.html { redirect_to admin_purchase_order_path(@purchase_order), alert: "Failed to create purchase from order." }
        end
      end
    end
  end

  private

  def set_purchase_order
    @purchase_order = Purchases::PurchaseOrder.find(params[:id])
  end

  def purchase_order_params
    params.require(:purchase_order).permit(
      :vendor_id,
      :order_date,
      :notes,
      purchase_order_lines_attributes: [
        :id,
        :product_id,
        :quantity,
        :unit_price,
        :_destroy
      ]
    )
  end

  def datatable_json
    search_value = params[:search][:value] if params[:search].present?

    purchase_orders = Purchases::PurchaseOrder.includes(:vendor, :user, :purchase)

    # Apply search if provided
    if search_value.present?
      purchase_orders = purchase_orders.where(
        "purchases_purchase_orders.purchase_order_number ILIKE :search OR
         purchases_vendors.name ILIKE :search",
        search: "%#{search_value}%"
      )
    end

    # Apply sorting
    if params[:order].present?
      order_column = params[:order]["0"][:column].to_i
      direction = params[:order]["0"][:dir]

      case order_column
      when 1
        purchase_orders = purchase_orders.order(purchase_order_number: direction)
      when 2
        purchase_orders = purchase_orders.order(order_date: direction)
      when 3
        purchase_orders = purchase_orders.joins(:vendor).order("purchases_vendors.name #{direction}")
      when 4
        purchase_orders = purchase_orders.joins(:user).order("users.first_name #{direction}, users.last_name #{direction}")
      when 5
        purchase_orders = purchase_orders.order(status: direction)
      else
        purchase_orders = purchase_orders.order(created_at: :desc)
      end
    else
      purchase_orders = purchase_orders.order(created_at: :desc)
    end

    # Pagination
    purchase_orders = purchase_orders.page(params[:start].to_i / params[:length].to_i + 1).per(params[:length].to_i)

    {
      draw: params[:draw].to_i,
      recordsTotal: Purchases::PurchaseOrder.count,
      recordsFiltered: purchase_orders.total_count,
      data: purchase_orders.map do |purchase_order|
        [
          purchase_order.id,
          purchase_order.purchase_order_number,
          friendly_date(current_user, purchase_order.order_date),
          purchase_order.vendor.name,
          purchase_order.user.name,
          purchase_order.status.humanize,
          render_to_string(
            partial: "admin/purchase_orders/actions",
            formats: [ :html ],
            locals: { purchase_order: purchase_order }
          )
        ]
      end
    }
  end
end
