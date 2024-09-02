class Admin::CommissionRangesController < Admin::AdminController
  before_action :set_commission_range, only: [ :edit, :update, :destroy ]

  def index
    if params[:location_id].present?
      @location = Location.find_by(id: params[:location_id])
      @commission_ranges = @location.commission_ranges
    else
      @commission_ranges = CommissionRange.all.includes(:location)
    end

    @datatable_options = "resource_name:'CommissionRange';create_button:true;sort_0_asc;sort_1_asc;"

    respond_to do |format|
      format.html # index.html.erb
      format.turbo_stream { render turbo_stream: turbo_stream.replace("commission-ranges-table", partial: "admin/commission_ranges/table", locals: { commission_ranges: @commission_ranges }) }
    end
  end

  def new
    @commission_range = CommissionRange.new
    @location = params[:location_id].present? ? Location.find(params[:location_id]) : @current_location
  end

  def create
    @commission_range = CommissionRange.create(commission_range_params)
    redirect_to admin_commission_ranges_path
  end

  def edit
    set_commission_range
    @location = @commission_range.location
  end

  def update
    set_commission_range
    @commission_range.update(commission_range_params)
    redirect_to admin_commission_ranges_path
  end

  def destroy
    set_commission_range
    @commission_range.destroy
    redirect_to admin_commission_ranges_path
  end

  private

  def set_commission_range
    @commission_range = CommissionRange.find(params[:id])
  end

  def commission_range_params
    params.require(:commission_range).permit(:start_amount, :end_amount, :commission_percentage)
  end
end
