class Admin::CommissionsController < Admin::AdminController
  def index
    @seller = User.find(params[:seller_id]) if params[:seller_id].present?
    @date_range = (params[:from_date].present? && params[:to_date].present?) ? (params[:from_date].to_date..params[:to_date].to_date) : nil

    sales_search_service = Services::Queries::SalesSearchService.new(location: @current_location, seller: @seller, date_range: @date_range)
    @sales_on_month_for_location = sales_search_service.sales_on_month_for_location

    Services::Sales::OrderCommissionService.recalculate_commissions

    if current_user.any_admin_or_supervisor?
      @commissions = Commission.all.includes([ :user, :order ]).order(id: :desc)
    else
      @commissions = Commission.joins(:order).where(orders: { location: @current_location }).includes([ :user, :order ]).order(id: :desc)
    end

    @datatable_options = "resource_name:'Commission';create_button:false;sort_0_desc;hide_0;"

    respond_to do |format|
      format.html
    end
  end

  def show
    @commission = Commission.find(params[:id])
  end
end
