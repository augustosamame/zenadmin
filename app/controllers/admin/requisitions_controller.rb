class Admin::RequisitionsController < Admin::AdminController
  before_action :set_requisition, only: [ :show, :edit, :update, :destroy, :approve, :reject, :fulfill ]

  def index
    respond_to do |format|
      format.html do
        @requisitions = Requisition.all.includes(:location, :warehouse, :user).order(id: :desc)
        @datatable_options = "resource_name:'Requisition'; sort_0_desc;"
      end

      format.json do
        render json: datatable_json
      end
    end
  end

  def show
  end

  def new
    @requisition = Requisition.new
    @requisition.user_id = current_user.id
    @requisition.requisition_date = Time.now
    @requisition.requisition_lines.build
  end

  def create
    @requisition = Requisition.new(requisition_params)
    @requisition.user_id = current_user.id
    @requisition.requisition_type = "manual"

    if @requisition.save
      redirect_to admin_requisitions_path, notice: "El pedido se creó correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @requisition.update(requisition_params)
      redirect_to admin_requisitions_path, notice: "El pedido se actualizó correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @requisition.destroy
      flash[:notice] = "El pedido se eliminó correctamente."
    else
      flash[:alert] = "El pedido no puede ser eliminada."
    end
    redirect_to admin_requisitions_path
  end

  def approve
    if @requisition.may_approve?
      @requisition.approve!
      flash[:notice] = "El pedido ha sido aprobada."
    else
      flash[:alert] = "No se puede aprobar el pedido."
    end
    redirect_to admin_requisition_path(@requisition)
  end

  def reject
    if @requisition.may_reject?
      @requisition.reject!
      flash[:notice] = "El pedido ha sido rechazada."
    else
      flash[:alert] = "No se puede rechazar el pedido."
    end
    redirect_to admin_requisition_path(@requisition)
  end

  def fulfill
    if @requisition.may_fulfill?
      @requisition.fulfill!
      flash[:notice] = "El pedido ha sido cumplida."
    else
      flash[:alert] = "No se puede cumplir el pedido."
    end
    redirect_to admin_requisition_path(@requisition)
  end

  private

  def set_requisition
    @requisition = Requisition.find(params[:id])
  end

  def requisition_params
    params.require(:requisition).permit(:location_id, :warehouse_id, :requisition_date, :comments, :stage, :status, :requisition_type, requisition_lines_attributes: [ :id, :product_id, :automatic_quantity, :presold_quantity, :manual_quantity, :supplied_quantity, :status, :_destroy ])
  end
end
