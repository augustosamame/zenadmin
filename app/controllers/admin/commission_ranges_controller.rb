class Admin::CommissionRangesController < Admin::AdminController
  before_action :set_commission_range, only: [ :edit, :update, :destroy ]

  def index
    authorize! :read, CommissionRange

    @commission_ranges = if @current_location
      CommissionRange.where(location: @current_location)
                    .includes(:location)
                    .order("locations.name, min_sales")
    else
      CommissionRange.includes(:location)
                    .order("locations.name, min_sales")
    end

    @datatable_options = "resource_name:'CommissionRange';create_button:true;sort_0_asc;sort_1_asc;"

    respond_to do |format|
      format.html # index.html.erb
      format.turbo_stream { render turbo_stream: turbo_stream.replace("commission-ranges-table", partial: "admin/commission_ranges/table", locals: { commission_ranges: @commission_ranges }) }
    end
  end

  def new
    authorize! :create, CommissionRange
    @commission_range = CommissionRange.new
    period = Date.today.day <= 15 ? "I" : "II"
    @commission_range.year_month_period = "#{Date.today.strftime('%Y_%m')}_#{period}"
    @location = params[:location_id].present? ? Location.find(params[:location_id]) : (@current_location || Location.first)
  end

  def create
    authorize! :create, CommissionRange
    @commission_range = CommissionRange.create(commission_range_params)
    redirect_to admin_commission_ranges_path
  end

  def edit
    authorize! :update, @commission_range
    set_commission_range
    @location = @commission_range.location
  end

  def update
    authorize! :update, @commission_range
    set_commission_range
    @commission_range.update(commission_range_params)
    redirect_to admin_commission_ranges_path
  end

  def destroy
    authorize! :destroy, @commission_range
    set_commission_range
    @commission_range.destroy
    redirect_to admin_commission_ranges_path
  end

  private

  def set_commission_range
    @commission_range = CommissionRange.find(params[:id])
  end

  def commission_range_params
    params.require(:commission_range).permit(:start_amount, :end_amount, :commission_percentage, :year_month_period, :location_id)
  end
end
