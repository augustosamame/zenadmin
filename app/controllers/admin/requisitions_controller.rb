class Admin::RequisitionsController < Admin::AdminController
  before_action :set_requisition, only: [ :show, :update, :destroy, :approve, :reject, :fulfill ]
  before_action :set_locations_and_warehouses, only: [ :new, :create, :edit, :update, :new_automatic ]

  def index
    respond_to do |format|
      format.html do
        if current_user.any_admin_or_supervisor?
          @requisitions = Requisition.all.includes(:location, :warehouse, :user).order(id: :desc)
        else
          @requisitions = Requisition.where(location: @current_location).includes(:location, :warehouse, :user).order(id: :desc)
        end
        @datatable_options = "resource_name:'Requisition'; sort_0_desc; hide_0; create_button:false;"
      end

      format.json do
        render json: datatable_json
      end
    end
  end

  def show
    @requisition = Requisition.includes(
      requisition_lines: [ :product ],
      location: {
        warehouses: :warehouse_inventories
      }
    ).find(params[:id])
    respond_to do |format|
      format.html
      format.pdf do
        pdf = RequisitionPdf.new(@requisition, current_user)
        send_data pdf.render,
                  filename: "pedido_#{@requisition.custom_id}.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end

  def new
    @requisition = Requisition.new
    @requisition.user_id = current_user.id
    @requisition.requisition_date = Time.current
    # @requisition.requisition_lines.build

    negative_stock_products = Product.includes(:warehouse_inventories)
                              .joins(:warehouse_inventories)
                              .where(warehouse_inventories: {
                                warehouse_id: @current_warehouse.id,
                                stock: ...-1  # Using Ruby range syntax for "less than 0"
                              })
    negative_stock_products.each do |product|
      current_stock = product.stock(@current_warehouse)
      @requisition.requisition_lines.build(
        product: product,
        current_stock: current_stock,
        presold_quantity: current_stock.abs,  # Convert negative stock to positive number
        automatic_quantity: 0,
        manual_quantity: current_stock.abs    # Set initial manual quantity to match deficit
      )
    end
  end

  def new_automatic
    main_warehouse = Warehouse.main_warehouse

    # Create a new requisition object (not saved to database)
    @requisition = Requisition.new(
      requisition_date: Time.current,
      user_id: current_user.id,
      requisition_type: "automatic",
      location_id: @current_location.id,
      warehouse_id: main_warehouse.id
    )

    # Build requisition lines for ALL products that exist in the warehouse
    products = Product.includes(:warehouse_inventories)
              .joins(:warehouse_inventories)
              .where(warehouse_inventories: {
                warehouse_id: @current_warehouse.id
              })

    products.each do |product|
      current_stock = product.stock(@current_warehouse)
      automatic_qty = Services::Inventory::AutomaticRequisitionsService.automatic_weekly_requisition_quantity(product, @current_location)
      presold_qty = Services::Inventory::AutomaticRequisitionsService.unrequisitioned_presold_quantity(product, @current_location)
      
      @requisition.requisition_lines.build(
        product: product,
        current_stock: current_stock,
        presold_quantity: presold_qty,
        automatic_quantity: automatic_qty,
        manual_quantity: automatic_qty  # Use automatic quantity as initial manual quantity
      )
    end

    render :new
  end

  def create
    @requisition = Requisition.new(requisition_params)
    @requisition.warehouse_id = @requisition.location&.warehouses&.first&.id
    @requisition.user_id = current_user.id
    # Only set to manual if no requisition_type was provided in params
    @requisition.requisition_type = "manual" if @requisition.requisition_type.blank?

    begin
      Requisition.transaction do
        if @requisition.save
          action = params[:commit] || params[:debug_commit_value]
          Rails.logger.info "Action to perform: #{action}"

          case action
          when "submit_to_warehouse"
            Rails.logger.info "Attempting to submit new requisition to warehouse"
            if @requisition.may_submit?
              @requisition.submit!
              Rails.logger.info "Successfully submitted requisition"
              flash[:notice] = "El pedido se creó y envió al Almacén Principal correctamente."
            else
              Rails.logger.error "Cannot submit - current stage: #{@requisition.stage}"
              raise AASM::InvalidTransition.new("No se puede enviar el pedido en su estado actual")
            end
          else
            Rails.logger.info "Saving as draft"
            flash[:notice] = "El pedido se guardó como borrador correctamente."
          end

          redirect_to admin_requisitions_path
        else
          Rails.logger.error "Creation failed: #{@requisition.errors.full_messages}"
          set_locations_and_warehouses
          render :new, status: :unprocessable_entity
        end
      end
    rescue AASM::InvalidTransition => e
      Rails.logger.error "AASM transition error: #{e.message}"
      flash.now[:alert] = e.message
      set_locations_and_warehouses
      render :new, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "Unexpected error: #{e.message}"
      flash.now[:alert] = "Error al crear el pedido: #{e.message}"
      set_locations_and_warehouses
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Optimize edit action with proper eager loading
    @requisition = Requisition.find(params[:id])
    @requisition.update_columns(warehouse_id: @requisition.location&.warehouses&.first&.id)
    @current_warehouse = @requisition.warehouse

    @requisition_lines = RequisitionLine
      .joins(:product)
      .where(requisition_id: @requisition.id, products: { status: :active })
      .order(
        Arel.sql("CASE WHEN requisition_lines.manual_quantity > 0 THEN 0 ELSE 1 END"),
        Arel.sql("products.name ASC")
      )
      .includes(product: [ :warehouse_inventories ])

    # Pre-calculate stocks in a single query
    product_stocks = WarehouseInventory
      .where(warehouse: @current_warehouse, product_id: @requisition_lines.map(&:product_id))
      .pluck(:product_id, :stock)
      .to_h

    @requisition_lines.each do |line|
      line.current_stock = product_stocks[line.product_id] || 0
    end
  end

  def update
    Rails.logger.info "=== Starting Requisition Update ==="
    Rails.logger.info "Current requisition stage: #{@requisition.stage}"

    begin
      Requisition.transaction do
        permitted_params = requisition_params

        if @requisition.update(permitted_params)
          Rails.logger.info "Basic update successful"
          action = params[:commit] || params[:debug_commit_value]
          Rails.logger.info "Action to perform: #{action}"

          case action
          when "submit_to_warehouse"
            Rails.logger.info "Attempting to submit requisition to warehouse"
            if @requisition.req_draft? && @requisition.may_submit?
              @requisition.submit!
              Rails.logger.info "Successfully submitted requisition"
              flash[:notice] = "Pedido enviado al Almacén Principal correctamente."
            else
              Rails.logger.error "Cannot submit - current stage: #{@requisition.stage}"
              raise AASM::InvalidTransition.new("No se puede enviar el pedido en su estado actual")
            end
          when "plan"
            Rails.logger.info "Attempting to plan requisition"
            if @requisition.req_submitted?
              # Set nil or blank planned quantities to 0
              @requisition.requisition_lines.each do |line|
                if line.planned_quantity.blank?
                  line.planned_quantity = 0
                  line.save(validate: false)
                  Rails.logger.info "Set blank planned_quantity to 0 for line ##{line.id}"
                end
              end

              # We'll proceed with planning even if some quantities are 0
              # This allows users to not have to manually enter 0 for lines they don't want to plan

              # If we get here, all lines have planned quantities
              Rails.logger.info "About to plan! requisition ##{@requisition.id}"
              @requisition.plan!
              Rails.logger.info "Planned requisition ##{@requisition.id}"
              flash[:notice] = "Pedido planificado correctamente."
            else
              raise AASM::InvalidTransition.new("No se puede planificar el pedido en su estado actual")
            end
          else
            Rails.logger.info "No special action requested, normal update"
            flash[:notice] = "Pedido actualizado correctamente."
          end

          redirect_to admin_requisitions_path
        else
          Rails.logger.error "Update failed: #{@requisition.errors.full_messages}"
          set_locations_and_warehouses
          render :edit, status: :unprocessable_entity
        end
      end
    rescue AASM::InvalidTransition => e
      Rails.logger.error "AASM transition error: #{e.message}"
      flash.now[:alert] = e.message
      set_locations_and_warehouses
      render :edit, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "Unexpected error: #{e.message}"
      flash.now[:alert] = "Error al actualizar el pedido: #{e.message}"
      set_locations_and_warehouses
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

  def set_locations_and_warehouses
    if current_user.any_admin_or_supervisor?
      @origin_locations = Location.all
    else
      @origin_locations = Location.where(id: @current_location.id)
    end
    @requisition_warehouses = Warehouse.where(is_main: true)
    @all_products = Product.active.order(:name)
  end

  def requisition_params
    # First, preprocess the params to mark empty records for destruction
    if params[:requisition][:requisition_lines_attributes].present?
      params[:requisition][:requisition_lines_attributes].each do |key, line_params|
        # If there's only an ID and no other meaningful attributes, mark it for destruction
        if line_params[:id].present? &&
           (line_params[:product_id].blank? || line_params.keys.size <= 1)
          params[:requisition][:requisition_lines_attributes][key][:_destroy] = "1"
        end
      end
    end

    filtered_params = params.require(:requisition).permit(
      :location_id,
      :warehouse_id,
      :requisition_date,
      :comments,
      :status,
      :requisition_type,
      requisition_lines_attributes: [
        :id,
        :product_id,
        :automatic_quantity,
        :presold_quantity,
        :manual_quantity,
        :planned_quantity,
        :supplied_quantity,
        :status,
        :_destroy
      ]
    )

    # Filter out invalid requisition lines, but keep ones marked for destruction
    if filtered_params[:requisition_lines_attributes].present?
      filtered_params[:requisition_lines_attributes].reject! do |_, line_params|
        # Don't reject if it's marked for destruction
        next false if line_params[:_destroy].present? && line_params[:_destroy] == "1"

        # Otherwise, apply the regular validation
        line_params[:product_id].blank? ||
        line_params[:manual_quantity].blank? ||
        line_params[:manual_quantity].to_i <= 0
      end
    end

    filtered_params
  end
end
