class Admin::PlannedStockTransfersController < Admin::AdminController
  before_action :set_planned_stock_transfer, only: [:show, :edit, :update, :destroy, :create_stock_transfer]

  def index
    respond_to do |format|
      format.html do
        if current_user.any_admin_or_supervisor?
          @planned_stock_transfers = PlannedStockTransfer.includes(:origin_warehouse, :destination_warehouse, :user).order(id: :desc)
          @default_object_options_array = [
            { event_name: "show", label: "Ver", icon: "eye" },
            { event_name: "edit", label: "Editar", icon: "pencil" },
            { event_name: "delete", label: "Eliminar", icon: "trash" },
            { event_name: "create_stock_transfer", label: "Crear Transferencia", icon: "truck" }
          ]
        else
          @planned_stock_transfers = PlannedStockTransfer.includes(:origin_warehouse, :destination_warehouse, :user)
                                .where(origin_warehouse: { id: @current_warehouse.id })
                                .or(PlannedStockTransfer.where(destination_warehouse: { id: @current_warehouse.id }))
                                .order(id: :desc)
          @default_object_options_array = [
            { event_name: "show", label: "Ver", icon: "eye" },
            { event_name: "create_stock_transfer", label: "Crear Transferencia", icon: "truck" }
          ]
        end

        if @planned_stock_transfers.size > 2000
          @datatable_options = "server_side:true;resource_name:'PlannedStockTransfer'; sort_0_desc;"
        else
          @datatable_options = "resource_name:'PlannedStockTransfer'; sort_0_desc;"
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
    @planned_stock_transfer = PlannedStockTransfer.new
    @planned_stock_transfer.user_id = current_user.id
    @planned_stock_transfer.planned_date = Time.zone.now
    @planned_stock_transfer.planned_stock_transfer_lines.build
    @origin_warehouses = current_user.any_admin_or_supervisor? ? Warehouse.all : Warehouse.where(id: @current_warehouse&.id)
    @destination_warehouses = current_user.any_admin_or_supervisor? ? Warehouse.all : (Warehouse.all - @origin_warehouses)
    set_form_variables
  end

  def create
    @planned_stock_transfer = PlannedStockTransfer.new(planned_stock_transfer_params)
    @planned_stock_transfer.user_id = current_user.id
    
    if @planned_stock_transfer.save
      redirect_to admin_planned_stock_transfers_path, notice: "La transferencia de Stock planificada se creó correctamente."
    else
      set_form_variables
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @origin_warehouses = current_user.any_admin_or_supervisor? ? Warehouse.all : Warehouse.where(id: @current_warehouse&.id)
    @destination_warehouses = Warehouse.all - @origin_warehouses
    set_form_variables
  end

  def update
    if @planned_stock_transfer.update(planned_stock_transfer_params)
      redirect_to admin_planned_stock_transfers_path, notice: "La transferencia de Stock planificada se actualizó correctamente."
    else
      set_form_variables
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @planned_stock_transfer.destroy
      flash[:notice] = "La transferencia de Stock planificada se eliminó correctamente."
    else
      flash[:alert] = "La transferencia de Stock planificada no puede ser eliminada."
    end
    redirect_to admin_planned_stock_transfers_path
  end

  def create_stock_transfer
    service = Services::Inventory::PlannedStockTransferService.new(@planned_stock_transfer)
    
    if service.create_stock_transfer(current_user)
      redirect_to admin_stock_transfers_path, notice: "Se ha creado una transferencia de stock a partir de la transferencia planificada."
    else
      redirect_to admin_planned_stock_transfers_path, alert: "No se pudo crear la transferencia de stock: #{service.errors.join(', ')}"
    end
  end

  private

  def set_planned_stock_transfer
    @planned_stock_transfer = PlannedStockTransfer.find(params[:id])
  end

  def set_form_variables
    @header_title = "Nueva Transferencia de Stock Planificada"
    @button_label = "Grabar Transferencia de Stock Planificada"
    @almacen_de_origen_label = "Almacén de Origen"
  end

  def planned_stock_transfer_params
    params.require(:planned_stock_transfer).permit(:origin_warehouse_id, :destination_warehouse_id, :planned_date, :comments, planned_stock_transfer_lines_attributes: [:id, :product_id, :quantity, :_destroy])
  end

  def datatable_json
    search_term = params.dig(:search, :value).presence
    page = (params[:start].to_i / params[:length].to_i) + 1
    per_page = params[:length].to_i

    planned_stock_transfers = PlannedStockTransfer.includes(:origin_warehouse, :destination_warehouse, :user)
    
    if current_user.any_admin_or_supervisor?
      # No additional filtering needed for admin/supervisor
    else
      planned_stock_transfers = planned_stock_transfers
                              .where(origin_warehouse: { id: @current_warehouse.id })
                              .or(PlannedStockTransfer.where(destination_warehouse: { id: @current_warehouse.id }))
    end

    if search_term.present?
      planned_stock_transfers = planned_stock_transfers.joins(:user)
                                .where("planned_stock_transfers.custom_id ILIKE ? OR users.first_name ILIKE ? OR users.last_name ILIKE ?", 
                                      "%#{search_term}%", "%#{search_term}%", "%#{search_term}%")
    end

    total_count = planned_stock_transfers.count
    
    # Apply sorting
    if params[:order].present?
      order_column = params[:order]["0"][:column].to_i
      order_direction = params[:order]["0"][:dir]
      
      case order_column
      when 0
        planned_stock_transfers = planned_stock_transfers.order(custom_id: order_direction)
      when 2
        planned_stock_transfers = planned_stock_transfers.joins(:user).order("users.first_name #{order_direction}, users.last_name #{order_direction}")
      when 6
        planned_stock_transfers = planned_stock_transfers.order(planned_date: order_direction)
      when 7
        planned_stock_transfers = planned_stock_transfers.order(status: order_direction)
      when 8
        planned_stock_transfers = planned_stock_transfers.order(fulfillment_status: order_direction)
      else
        planned_stock_transfers = planned_stock_transfers.order(id: :desc)
      end
    else
      planned_stock_transfers = planned_stock_transfers.order(id: :desc)
    end
    
    # Apply pagination
    planned_stock_transfers = planned_stock_transfers.page(page).per(per_page)
    
    {
      draw: params[:draw].to_i,
      recordsTotal: total_count,
      recordsFiltered: total_count,
      data: planned_stock_transfers.as_json(
        include: {
          user: { only: [:id], methods: [:name] },
          origin_warehouse: { only: [:id, :name] },
          destination_warehouse: { only: [:id, :name] }
        },
        methods: [:total_products, :total_fulfilled_products]
      )
    }
  end
end
