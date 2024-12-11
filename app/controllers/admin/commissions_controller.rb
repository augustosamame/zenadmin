class Admin::CommissionsController < Admin::AdminController
  def index
    @seller = User.find(params[:seller_id]) if params[:seller_id].present?

    # Update to use filter params
    if params[:filter].present?
      @from_date = params[:filter][:from_date].presence&.to_date
      @to_date = params[:filter][:to_date].presence&.to_date
      @status_paid_out = params[:filter][:status_paid_out] == "1"
    end

    @date_range = (@from_date && @to_date) ? (@from_date..@to_date) : nil

    sales_search_service = Services::Queries::SalesSearchService.new(location: @current_location, seller: @seller, date_range: @date_range)
    @sales_on_month_for_location = sales_search_service.sales_on_month_for_location

    Services::Sales::OrderCommissionService.recalculate_commissions

    @commissions = if current_user.any_admin_or_supervisor?
      Commission.all.includes([ :user, :order ])
    else
      Commission.joins(:order).where(orders: { location: @current_location }).includes([ :user, :order ])
    end

    # Apply filters
    @commissions = @commissions.where(created_at: @date_range) if @date_range
    @commissions = @commissions.where(status: :status_paid_out) if @status_paid_out
    @commissions = @commissions.order(id: :desc)

    @datatable_options = "resource_name:'Commission';create_button:false;sort_0_desc;hide_0;"

    respond_to do |format|
      format.html
    end
  end

  def show
    @commission = Commission.find(params[:id])
  end
end
