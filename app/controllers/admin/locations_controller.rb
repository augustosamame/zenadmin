class Admin::LocationsController < Admin::AdminController
  requires_location_selection :sales_targets
  before_action :set_location, only: [ :edit, :update, :destroy, :commission_ranges ]

  def index
    authorize! :read, Location
    @locations = Location.all
    @datatable_options = "resource_name:'Location';create_button:true;sort_0_desc;"
  end

  def new
    authorize! :create, Location
    @location = Location.new
    @location.commission_ranges.build
  end

  def create
    authorize! :create, Location
    @location = Location.new(location_params)
    if @location.save
      if params[:location][:commission_ranges_attributes].present?
        redirect_to admin_commission_ranges_path(location_id: @location.id)
      else
        redirect_to admin_locations_path
      end
    else
      if params[:location][:commission_ranges_attributes].present?
        @commission_range = @location.commission_ranges.first
        render "admin/commission_ranges/new", status: :unprocessable_entity
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  def edit
    authorize! :update, @location
    @location.commission_ranges.build if @location.commission_ranges.empty?
  end

  def update
    authorize! :update, @location
    if @location.update(location_params)
      if params[:location][:commission_ranges_attributes].present?
        redirect_to admin_commission_ranges_path(location_id: @location.id)
      else
        redirect_to admin_locations_path
      end
    else
      if params[:location][:commission_ranges_attributes].present?
        @commission_range = @location.commission_ranges.first
        redirect_to(
          request.referer || edit_admin_commission_range_path(@commission_range),
          status: :see_other,  # 303 status code
          alert: @location.errors.full_messages.join(", ")
        )
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def destroy
    authorize! :destroy, @location
    @location.destroy
    redirect_to admin_locations_path
  end

  def commission_ranges
    authorize! :read, @location
    @commission_ranges = @location.commission_ranges

    respond_to do |format|
      format.json { render json: @commission_ranges }
    end
  end

  def sales_targets
    authorize! :read, Location
    @current_period = CommissionRange.current_year_month_period

    # Get commission ranges for current location
    @commission_ranges = @current_location.commission_ranges
      .where(year_month_period: @current_period)
      .order(:min_sales)

    # Get date range for current period
    date_range = SellerBiweeklySalesTarget.period_datetime_range(@current_period)

    # Calculate total sales for current period
    @total_sales = Order.all
      .where(location: @current_location)
      .where(order_date: date_range[0]..date_range[1])
      .sum(:total_price_cents) / 100.0

    # Find active commission range based on total sales
    @active_commission_range = CommissionRange.find_commission_for_sales(
      @total_sales,
      @current_location,
      Date.current
    )

    # Get seller targets for current period
    @seller_targets = SellerBiweeklySalesTarget
      .includes(:seller)
      .where(location: @current_location, year_month_period: @current_period)
      .order("users.first_name, users.last_name")

    @total_seller_target = @seller_targets.sum(:sales_target_cents) / 100.0
  end

  private

  def set_location
    @location = Location.find(params[:id])
  end

  def location_params
    params.require(:location).permit(:name, :address, :phone, :email, :description, :latitude, :longitude, :status, :max_discount, commission_ranges_attributes: [ :id, :_destroy, :min_sales, :max_sales, :commission_percentage, :location_id, :user_id, :year_month_period ])
  end
end
