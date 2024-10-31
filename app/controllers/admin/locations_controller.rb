class Admin::LocationsController < Admin::AdminController
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

  private

  def set_location
    @location = Location.find(params[:id])
  end

  def location_params
    params.require(:location).permit(:name, :address, :phone, :email, :description, :latitude, :longitude, :status, commission_ranges_attributes: [ :id, :_destroy, :min_sales, :max_sales, :commission_percentage, :location_id, :user_id, :year_month_period ])
  end
end
