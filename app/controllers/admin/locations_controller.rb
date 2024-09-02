class Admin::LocationsController < Admin::AdminController
  before_action :set_location, only: [ :edit, :update, :destroy, :commission_ranges ]

  def index
    @locations = Location.all
    @datatable_options = "resource_name:'Location';create_button:true;sort_0_desc;"
  end

  def new
    @location = Location.new
    @location.commission_ranges.build
  end

  def create
    @location = Location.create(location_params)
    redirect_to admin_locations_path
  end

  def edit
    @location.commission_ranges.build if @location.commission_ranges.empty?
  end

  def update
    if @location.update(location_params)
      redirect_to admin_locations_path
    else
      byebug
      render :edit
    end
  end

  def destroy
    @location.destroy
    redirect_to admin_locations_path
  end

  def commission_ranges
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
    params.require(:location).permit(:name, :address, :phone, :email, :description, :latitude, :longitude, :status, commission_ranges_attributes: [:id, :_destroy, :min_sales, :max_sales, :commission_percentage, :location_id, :user_id])
  end
end