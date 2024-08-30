class Admin::StockTransfersController < Admin::AdminController
  before_action :set_stock_transfer, only: [ :show, :edit, :update, :destroy, :set_to_in_transit, :set_to_complete ]

  def index
    respond_to do |format|
      format.html do
        @stock_transfers = StockTransfer.all.includes(:origin_warehouse, :destination_warehouse, :user).order(id: :desc)

        if @stock_transfers.size > 50
          @datatable_options = "server_side:true;resource_name:'StockTransfer'; sort_0_desc;"
        else
          @datatable_options = "resource_name:'StockTransfer'; sort_0_desc;"
        end
      end

      format.json do
        render json: datatable_json
      end
    end
  end

  def show
  end

  def new
    @stock_transfer = StockTransfer.new
    @stock_transfer.user_id = current_user.id
    @stock_transfer.transfer_date = Time.zone.now
    @stock_transfer.stock_transfer_lines.build
  end

  def create
    @stock_transfer = StockTransfer.new(stock_transfer_params)
    @stock_transfer.user_id = current_user.id
    if @stock_transfer.save
      @stock_transfer.finish_transfer! if @stock_transfer.stage == "complete" || @stock_transfer.origin_warehouse_id.nil? # inventario inicial
      redirect_to admin_stock_transfers_path, notice: "La transferencia de Stock se creó correctamente."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @stock_transfer.update(stock_transfer_params)
      if @stock_transfer == "in_transit"
        @stock_transfer.start_transfer! unless @stock_transfer.in_transit?
      elsif @stock_transfer == "complete"
        @stock_transfer.finish_transfer! unless @stock_transfer.complete?
      end

      redirect_to admin_stock_transfers_path, notice: "La transferencia de Stock se actualizó correctamente."
    else
      render :edit
    end
  end

  def destroy
    if @stock_transfer.destroy
      flash[:notice] = "La transferencia de Stock se eliminó correctamente."
    else
      flash[:alert] = "La transferencia de Stock no puede ser eliminada. (#{@stock_transfer.errors.full_messages.join(', ')})"
    end
    redirect_to admin_stock_transfers_path
  end

  def set_to_in_transit
    if $global_settings[:stock_transfers_have_in_transit_step]
      if @stock_transfer.may_start_transfer?
        @stock_transfer.start_transfer!
        flash[:notice] = "El Stock fue entregado al Transportista."
      else
        flash[:alert] = "Error al intentar entregar el Stock al Transportista."
      end
    else
      flash[:alert] = "In Transit step is not enabled."
    end
    respond_to do |format|
      format.html { redirect_to admin_stock_transfers_path }
      format.js   # Responds to AJAX request (set_to_in_transit.js.erb)
    end
  end

  def set_to_complete
    if @stock_transfer.may_finish_transfer?
      @stock_transfer.finish_transfer!
      flash[:notice] = "Stock transfer set to Complete."
    else
      flash[:alert] = "Stock transfer could not be set to Complete."
    end
    respond_to do |format|
      format.html { redirect_to admin_stock_transfers_path }
      format.js   # Responds to AJAX request (set_to_complete.js.erb)
    end
  end

  private

  def set_stock_transfer
    @stock_transfer = StockTransfer.find(params[:id])
  end

  def stock_transfer_params
    params.require(:stock_transfer).permit(:origin_warehouse_id, :destination_warehouse_id, :guia, :transfer_date, :comments, :is_adjustment, :adjustment_type, stock_transfer_lines_attributes: [ :id, :product_id, :quantity, :_destroy ])
  end
end
