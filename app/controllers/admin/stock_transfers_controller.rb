class Admin::StockTransfersController < Admin::AdminController
  before_action :set_stock_transfer, only: [ :show, :edit, :update, :destroy, :set_to_in_transit, :set_to_complete ]

  def index
    respond_to do |format|
      format.html do
        @stock_transfers = StockTransfer.where(is_adjustment: false).includes(:origin_warehouse, :destination_warehouse, :user).order(id: :desc)

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

  def index_stock_adjustments
    respond_to do |format|
      format.html do
        @stock_transfers = StockTransfer.where(is_adjustment: true).includes(:origin_warehouse, :user).order(id: :desc)

        if @stock_transfers.size > 50
          @datatable_options = "server_side:true;resource_name:'StockAdjustment'; sort_0_desc;"
        else
          @datatable_options = "resource_name:'StockAdjustment'; sort_0_desc;"
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
    @is_adjustment = params[:stock_adjustment].present? && params[:stock_adjustment] == "true"
    @stock_transfer = StockTransfer.new
    @stock_transfer.user_id = current_user.id
    @stock_transfer.transfer_date = Time.zone.now
    @stock_transfer.stock_transfer_lines.build
    @origin_warehouses = current_user.any_admin_or_supervisor? ? Warehouse.all : Warehouse.where(id: @current_warehouse&.id)
    set_form_variables
  end

  def create
    @stock_transfer = StockTransfer.new(stock_transfer_params)
    @stock_transfer.user_id = current_user.id
    if @stock_transfer.save
      @stock_transfer.finish_transfer! if @stock_transfer.origin_warehouse_id.nil? # inventario inicial
      if @stock_transfer.is_adjustment
        redirect_to index_stock_adjustments_admin_stock_transfers_path, notice: "El ajuste de Stock se creó correctamente."
      else
        redirect_to admin_stock_transfers_path, notice: "La transferencia de Stock se creó correctamente."
      end
    else
      @is_adjustment = @stock_transfer.is_adjustment
      set_form_variables
      render :new, status: :unprocessable_entity
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
      @is_adjustment = @stock_transfer.is_adjustment
      set_form_variables
      render :edit, status: :unprocessable_entity
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

  def set_form_variables
    if @is_adjustment
      @header_title = "Nuevo Ajuste de Stock"
      @button_label = "Grabar Ajuste de Stock"
      @almacen_de_origen_label = "Almacén a Ajustar"
      @stock_transfer.is_adjustment = true
    else
      @header_title = "Nueva Transferencia de Stock"
      @button_label = "Grabar Transferencia de Stock"
      @almacen_de_origen_label = "Almacén de Origen"
    end
  end

  def stock_transfer_params
    params.require(:stock_transfer).permit(:origin_warehouse_id, :destination_warehouse_id, :guia, :transfer_date, :comments, :is_adjustment, :adjustment_type, stock_transfer_lines_attributes: [ :id, :product_id, :quantity, :_destroy ])
  end
end
