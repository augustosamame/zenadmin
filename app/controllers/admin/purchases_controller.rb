class Admin::PurchasesController < Admin::AdminController
  include MoneyRails::ActionViewExtension
  include CurrencyFormattable
  include AdminHelper

  before_action :set_purchase, only: [ :show, :edit, :update ]

  def index
    respond_to do |format|
      format.html do
        @purchases = Purchases::Purchase.includes(:vendor, :user, :purchase_order)
                                        .order(created_at: :desc)
                                        .limit(10)
        @datatable_options = "server_side:true;resource_name:'Purchase';sort_0_desc;hide_0;create_button:true;"
      end

      format.json do
        render json: datatable_json
      end
    end
  end

  def new
    @purchase = Purchases::Purchase.new
    @purchase.purchase_lines.build
    @purchase.purchase_invoices.build
    @purchase_orders = Purchases::PurchaseOrder.where(status: [ :draft, :approved, :pending ])
                                              .includes(:vendor)
                                              .order(created_at: :desc)
  end

  def create
    @purchase = Purchases::Purchase.new(purchase_params)
    @purchase.user_id = current_user.id
    @purchase.region_id = @current_region.id if @current_region.present?

    respond_to do |format|
      if @purchase.save
        # Update inventory
        Services::Inventory::PurchaseItemService.new(@purchase).update_inventory

        format.html { redirect_to admin_purchase_path(@purchase), notice: "Purchase was successfully created." }
        format.json { render :show, status: :created, location: @purchase }
      else
        @purchase_orders = Purchases::PurchaseOrder.where(status: [ :draft, :approved, :pending ])
                                                  .includes(:vendor)
                                                  .order(created_at: :desc)
        format.html { render :new }
        format.json { render json: @purchase.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
  end

  def edit
    @purchase_orders = Purchases::PurchaseOrder.where(status: [ :draft, :approved, :pending ])
                                              .includes(:vendor)
                                              .order(created_at: :desc)
  end

  def update
    respond_to do |format|
      if @purchase.update(purchase_params)
        format.html { redirect_to admin_purchase_path(@purchase), notice: "Purchase was successfully updated." }
        format.json { render :show, status: :ok, location: @purchase }
      else
        @purchase_orders = Purchases::PurchaseOrder.where(status: [ :draft, :approved, :pending ])
                                                  .includes(:vendor)
                                                  .order(created_at: :desc)
        format.html { render :edit }
        format.json { render json: @purchase.errors, status: :unprocessable_entity }
      end
    end
  end

  def get_purchase_order_details
    purchase_order = Purchases::PurchaseOrder.includes(:vendor, :purchase_order_lines, :transportista).find(params[:purchase_order_id])

    # Find the main warehouse for the region if available
    main_warehouse = purchase_order.region&.warehouses&.find_by(is_main: true)
    default_warehouse_id = main_warehouse&.id

    render json: {
      purchase_order_id: purchase_order.id,
      vendor_id: purchase_order.vendor_id,
      transportista_id: purchase_order.transportista_id,
      notes: purchase_order.notes,
      lines: purchase_order.purchase_order_lines.map do |line|
        {
          product_id: line.product_id,
          quantity: line.quantity,
          unit_price: line.unit_price.to_f,
          warehouse_id: default_warehouse_id
        }
      end
    }
  end

  def get_product_details
    product = Product.find(params[:product_id])

    render json: {
      id: product.id,
      name: product.name,
      price: product.price.to_f
    }
  end

  private

  def set_purchase
    @purchase = Purchases::Purchase.find(params[:id])
  end

  def purchase_params
    params.require(:purchase).permit(
      :vendor_id,
      :purchase_date,
      :notes,
      :transportista_id,
      :purchase_order_id,
      purchase_lines_attributes: [
        :id,
        :product_id,
        :quantity,
        :unit_price,
        :warehouse_id,
        :_destroy
      ],
      purchase_invoices_attributes: [
        :id,
        :purchase_invoice_date,
        :purchase_invoice_type,
        :custom_id,
        :amount_cents,
        :amount,
        :currency,
        :planned_payment_date,
        :_destroy
      ]
    )
  end

  def datatable_json
    search_value = params[:search][:value] if params[:search].present?

    purchases = Purchases::Purchase.includes(:vendor, :user, :purchase_order)

    # Apply search if provided
    if search_value.present?
      purchases = purchases.where(
        "purchases_purchases.custom_id ILIKE :search OR
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
        purchases = purchases.order(custom_id: direction)
      when 2
        purchases = purchases.order(purchase_date: direction)
      when 3
        purchases = purchases.joins(:vendor).order("purchases_vendors.name #{direction}")
      when 4
        purchases = purchases.joins(:user).order("users.first_name #{direction}, users.last_name #{direction}")
      when 5
        # Sort by purchase order number
        purchases = purchases.joins("LEFT JOIN purchases_purchase_orders ON purchases_purchases.purchase_order_id = purchases_purchase_orders.id")
                             .order("purchases_purchase_orders.custom_id #{direction}")
      else
        purchases = purchases.order(created_at: :desc)
      end
    else
      purchases = purchases.order(created_at: :desc)
    end

    # Pagination
    purchases = purchases.page(params[:start].to_i / params[:length].to_i + 1).per(params[:length].to_i)

    {
      draw: params[:draw].to_i,
      recordsTotal: Purchases::Purchase.count,
      recordsFiltered: purchases.total_count,
      data: purchases.map do |purchase|
        [
          purchase.id,
          purchase.custom_id,
          friendly_date(current_user, purchase.purchase_date),
          purchase.vendor.name,
          purchase.user.name,
          purchase.purchase_order&.custom_id || "-",
          render_to_string(
            partial: "admin/purchases/actions",
            formats: [ :html ],
            locals: { purchase: purchase }
          )
        ]
      end
    }
  end
end
