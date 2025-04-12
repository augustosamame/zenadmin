class Admin::StockTransfersController < Admin::AdminController
  before_action :set_stock_transfer, only: [ :show, :edit, :update, :destroy, :set_to_in_transit, :initiate_receive, :execute_receive ]

  def index
    respond_to do |format|
      format.html do
        if current_user.any_admin_or_supervisor?
          @stock_transfers = StockTransfer.includes(:origin_warehouse, :destination_warehouse, :user, :customer_user).where(is_adjustment: false).order(id: :desc)
          @default_object_options_array = [
            { event_name: "show", label: "Ver", icon: "eye" },
            { event_name: "edit", label: "Editar", icon: "pencil" },
            { event_name: "delete", label: "Eliminar", icon: "trash" },
            { event_name: "print", label: "Imprimir PDF", icon: "printer" }
          ]
        else
          @stock_transfers = StockTransfer.includes(:origin_warehouse, :destination_warehouse, :user, :customer_user)
                                .where(origin_warehouse: { id: @current_warehouse.id })
                                .or(StockTransfer.where(destination_warehouse: { id: @current_warehouse.id }))
                                .where(is_adjustment: false)
                                .order(id: :desc)
          @default_object_options_array = [
            { event_name: "edit", label: "Editar", icon: "pencil" },
            { event_name: "show", label: "Ver", icon: "eye" }
          ]
        end

        if @stock_transfers.size > 2000
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

        if @stock_transfers.size > 2000
          @datatable_options = "server_side:true;resource_name:'StockAdjustment'; sort_0_desc;"
        else
          @datatable_options = "resource_name:'StockAdjustment'; sort_0_desc;"
        end
        if current_user.any_admin_or_supervisor?
          @default_object_options_array = [
            { event_name: "show", label: "Ver", icon: "eye" },
            { event_name: "confirm", label: "Confirmar", icon: "check" }
          ]
        else
          @default_object_options_array = []
        end
      end

      format.json do
        render json: datatable_json
      end
    end
  end

  def show
    respond_to do |format|
      format.html
      format.pdf do
        pdf = StockTransferPdf.new(@stock_transfer, view_context)
        send_data pdf.render, filename: "stock_transfer_#{@stock_transfer.custom_id}.pdf",
                            type: "application/pdf",
                            disposition: "inline"
      end
    end
  end

  def new
    @is_adjustment = params[:stock_adjustment].present? && params[:stock_adjustment] == "true"
    @stock_transfer = StockTransfer.new
    @stock_transfer.user_id = current_user.id
    @stock_transfer.transfer_date = Time.zone.now
    @stock_transfer.stock_transfer_lines.build
    @origin_warehouses = current_user.any_admin_or_supervisor? ? Warehouse.all : Warehouse.where(id: @current_warehouse&.id)
    @destination_warehouses = current_user.any_admin_or_supervisor? ? Warehouse.all : (Warehouse.all - @origin_warehouses)
    @customer_transfer_enabled = $global_settings[:pos_can_create_orders_without_stock_transfers]
    set_form_variables
  end

  def create
    @stock_transfer = StockTransfer.new(stock_transfer_params)
    @stock_transfer.user_id = current_user.id
    if @stock_transfer.save
      @stock_transfer.finish_transfer! if @stock_transfer.origin_warehouse_id.nil? # inventario inicial

      # Create guia if requested and allowed by settings
      if !@stock_transfer.is_adjustment &&
         params[:stock_transfer][:create_guia] == "1" &&
         $global_settings[:show_sunat_guia_for_stock_transfers] # && ENV["RAILS_ENV"] == "production"
        GenerateEguiaFromStockTransfer.perform_async(@stock_transfer.id)
      end

      if @stock_transfer.is_adjustment
        @stock_transfer.finish_transfer!
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
    @is_adjustment = @stock_transfer.is_adjustment
    @origin_warehouses = current_user.any_admin_or_supervisor? ? Warehouse.all : Warehouse.where(id: @current_warehouse&.id)
    @destination_warehouses = current_user.any_admin_or_supervisor? ? Warehouse.all : (Warehouse.all - @origin_warehouses)
    @customer_transfer_enabled = $global_settings[:pos_can_create_orders_without_stock_transfers]
    set_form_variables
  end

  def update
    if @stock_transfer.update(stock_transfer_params)
      if @stock_transfer.in_transit?
        @stock_transfer.start_transfer! unless @stock_transfer.in_transit?
      elsif @stock_transfer.complete?
        @stock_transfer.finish_transfer! unless @stock_transfer.complete?
      end

      # Create guia if requested and allowed by settings
      if !@stock_transfer.is_adjustment &&
         params[:stock_transfer][:create_guia] == "1" &&
         $global_settings[:show_sunat_guia_for_stock_transfers] &&
         @stock_transfer.guias.empty?
        GenerateEguiaFromStockTransfer.perform_async(@stock_transfer.id)
      end

      WarehouseInventory.reconstruct_single_stock_transfer_stock(@stock_transfer)
      redirect_to admin_stock_transfers_path, notice: "La transferencia de Stock se actualizó correctamente."
    else
      @is_adjustment = @stock_transfer.is_adjustment
      set_form_variables
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @stock_transfer.current_user_for_destroy = current_user
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
      format.turbo_stream { render turbo_stream: turbo_stream.append_all("body", "<script>window.location.reload();</script>") }
    end
  end

  def initiate_receive
    @stock_transfer_lines = @stock_transfer.stock_transfer_lines.joins(:product).includes(:product).order("products.name ASC")
  end

  def execute_receive
    received_quantities = params[:received_quantities]
    ActiveRecord::Base.transaction do
      received_quantities.each do |line_id, quantity|
        line = @stock_transfer.stock_transfer_lines.find(line_id)
        line.update!(received_quantity: quantity.to_i)
      end

      @stock_transfer.finish_transfer!
    end
    redirect_to admin_stock_transfers_path, notice: "La transferencia de Stock se recibió correctamente."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to initiate_receive_admin_stock_transfer_path(@stock_transfer), alert: "Error al recibir la transferencia de Stock. (#{e.message})"
  end

  def adjustment_stock_transfer_admin_confirm
    @stock_transfer = StockTransfer.find(params[:id])

    if @stock_transfer.may_finish_transfer?
      if @stock_transfer.finish_transfer!
        flash[:notice] = "El ajuste de inventario fue confirmado exitosamente."
      else
        flash[:alert] = "Error al confirmar el ajuste de inventario."
      end
    else
      flash[:alert] = "Este ajuste no puede ser confirmado en su estado actual."
    end

    respond_to do |format|
      format.html { redirect_to index_stock_adjustments_admin_stock_transfers_path }
      format.turbo_stream { render turbo_stream: turbo_stream.append_all("body", "<script>window.location.reload();</script>") }
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
    @transportistas = Transportista.where(status: :active)
  end

  def stock_transfer_params
    params.require(:stock_transfer).permit(:origin_warehouse_id, :destination_warehouse_id, :guia, :transfer_date, :comments, :is_adjustment, :adjustment_type, :create_guia, :transportista_id, :to_customer, :customer_user_id, stock_transfer_lines_attributes: [ :id, :product_id, :quantity, :received_quantity, :_destroy ])
  end
end
