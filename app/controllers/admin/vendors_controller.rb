class Admin::VendorsController < Admin::AdminController
  include MoneyRails::ActionViewExtension
  include CurrencyFormattable
  include AdminHelper

  before_action :set_vendor, only: [ :show, :edit, :update, :destroy ]

  def index
    respond_to do |format|
      format.html do
        @vendors = Purchases::Vendor.order(created_at: :desc).limit(10)
        @datatable_options = "server_side:true;resource_name:'Vendor';sort_0_desc;hide_0;create_button:true;"
      end

      format.json do
        render json: datatable_json
      end
    end
  end

  def new
    @vendor = Purchases::Vendor.new
  end

  def create
    @vendor = Purchases::Vendor.new(vendor_params)

    respond_to do |format|
      if @vendor.save
        format.html { redirect_to admin_vendor_path(@vendor), notice: "Vendor was successfully created." }
        format.json { render :show, status: :created, location: @vendor }
      else
        format.html { render :new }
        format.json { render json: @vendor.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
  end

  def edit
  end

  def update
    respond_to do |format|
      if @vendor.update(vendor_params)
        format.html { redirect_to admin_vendor_path(@vendor), notice: "Vendor was successfully updated." }
        format.json { render :show, status: :ok, location: @vendor }
      else
        format.html { render :edit }
        format.json { render json: @vendor.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @vendor.purchase_orders.any?
      redirect_to admin_vendors_path, alert: "Cannot delete vendor with associated purchase orders."
    else
      @vendor.destroy
      redirect_to admin_vendors_path, notice: "Vendor was successfully deleted."
    end
  end

  private

  def set_vendor
    @vendor = Purchases::Vendor.find(params[:id])
  end

  def vendor_params
    params.require(:purchases_vendor).permit(
      :name,
      :contact_name,
      :email,
      :phone,
      :address,
      :tax_id,
      :notes
    )
  end

  def datatable_json
    search_value = params[:search][:value] if params[:search].present?

    vendors = Purchases::Vendor.all

    # Apply search if provided
    if search_value.present?
      vendors = vendors.where(
        "purchases_vendors.name ILIKE :search OR
         purchases_vendors.contact_name ILIKE :search OR
         purchases_vendors.email ILIKE :search OR
         purchases_vendors.tax_id ILIKE :search",
        search: "%#{search_value}%"
      )
    end

    # Apply sorting
    if params[:order].present?
      order_column = params[:order]["0"][:column].to_i
      direction = params[:order]["0"][:dir] == "asc" ? :asc : :desc

      case order_column
      when 1
        vendors = vendors.order(name: direction)
      when 2
        vendors = vendors.order(contact_name: direction)
      when 3
        vendors = vendors.order(email: direction)
      when 4
        vendors = vendors.order(phone: direction)
      else
        vendors = vendors.order(created_at: :desc)
      end
    else
      vendors = vendors.order(created_at: :desc)
    end

    # Pagination
    vendors = vendors.page(params[:start].to_i / params[:length].to_i + 1).per(params[:length].to_i)

    {
      draw: params[:draw].to_i,
      recordsTotal: Purchases::Vendor.count,
      recordsFiltered: search_value.present? ? vendors.total_count : Purchases::Vendor.count,
      data: vendors.map do |vendor|
        [
          vendor.id,
          vendor.name,
          vendor.contact_name,
          vendor.email,
          vendor.phone,
          render_to_string(
            partial: "admin/vendors/actions",
            formats: [ :html ],
            locals: { vendor: vendor }
          )
        ]
      end
    }
  end
end
