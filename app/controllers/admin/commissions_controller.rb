class Admin::CommissionsController < Admin::AdminController
  def index
    @from_date = params[:filter][:from_date] if params[:filter].present?
    @to_date = params[:filter][:to_date] if params[:filter].present?
    @status_paid_out = params[:filter][:status_paid_out] if params[:filter].present?

    @commissions = Commission.includes([ :user, :order ])
    @commissions = @commissions.where("created_at >= ?", @from_date) if @from_date.present?
    @commissions = @commissions.where("created_at <= ?", @to_date) if @to_date.present?
    @commissions = @commissions.where(status: "status_paid_out") if @status_paid_out.present?

    @datatable_options = "resource_name:'Commission';create_button:false;sort_2_desc;"

    respond_to do |format|
      format.html
    end
  end

  def show
    @commission = Commission.find(params[:id])
  end
end
