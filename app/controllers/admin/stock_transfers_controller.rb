class Admin::StockTransfersController < Admin::AdminController
  include ActionView::Helpers::TagHelper
  include ActionView::Context
  include AdminHelper
  include ApplicationHelper
  include Admin::StockTransfersHelper

  before_action :set_stock_transfer, only: [ :show, :edit, :update, :destroy, :set_to_in_transit, :initiate_receive, :execute_receive ]

  def index
    respond_to do |format|
      format.html do
        if current_user.any_admin_or_supervisor?
          @stock_transfers = StockTransfer.includes(:origin_warehouse, :destination_warehouse, :user, :customer_user, :vendor, :transportista).where(is_adjustment: false).order(id: :desc)
          @default_object_options_array = [
            { event_name: "show", label: "Ver", icon: "eye" },
            { event_name: "edit", label: "Editar", icon: "pencil" },
            { event_name: "delete", label: "Eliminar", icon: "trash" },
            { event_name: "print", label: "Imprimir PDF", icon: "printer" }
          ]
        else
          @stock_transfers = StockTransfer.includes(:origin_warehouse, :destination_warehouse, :user, :customer_user, :vendor, :transportista)
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
        @stock_transfers = StockTransfer.where(is_adjustment: true).includes(:origin_warehouse, :user, :vendor, :transportista).order(id: :desc)

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
        render json: datatable_json(true)
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
    @vendor_transfer_enabled = $global_settings[:pos_can_create_orders_without_stock_transfers] == true && current_user.has_any_role?("admin", "super_admin", "purchases", "warehouse_manager")
    @vendors = Purchases::Vendor.all
    set_form_variables
  end

  def create
    @stock_transfer = StockTransfer.new(stock_transfer_params)
    @stock_transfer.user_id = current_user.id
    if @stock_transfer.save
      @stock_transfer.finish_transfer! if @stock_transfer.origin_warehouse_id.nil? # inventario inicial

      # Start transfer automatically for vendor transfers
      @stock_transfer.start_transfer! if @stock_transfer.vendor_id.present?

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
    @vendor_transfer_enabled = $global_settings[:pos_can_create_orders_without_stock_transfers] == true && current_user.has_any_role?("admin", "super_admin", "purchases", "warehouse_manager")
    @vendors = Purchases::Vendor.all
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

  def datatable_json(is_adjustment = false)
    # Start with the base query depending on whether we're showing adjustments or regular transfers
    stock_transfers = if is_adjustment
      StockTransfer.where(is_adjustment: true)
    else
      if current_user.any_admin_or_supervisor?
        StockTransfer.where(is_adjustment: false)
      else
        # For non-admin users, show transfers related to their warehouse
        # and also include transfers with vendors (purchases)
        StockTransfer.left_joins(:origin_warehouse, :destination_warehouse)
                    .where(is_adjustment: false)
                    .where("origin_warehouse_id = ? OR destination_warehouse_id = ? OR vendor_id IS NOT NULL",
                          @current_warehouse&.id, @current_warehouse&.id)
      end
    end

    # Apply search if provided
    if params[:search] && params[:search][:value].present?
      search_term = "%#{params[:search][:value]}%"
      stock_transfers = stock_transfers.joins(:user)
                                      .left_joins(:origin_warehouse, :destination_warehouse, :vendor, :customer_user)
                                      .where("stock_transfers.custom_id ILIKE ? OR users.name ILIKE ? OR warehouses.name ILIKE ? OR destination_warehouses.name ILIKE ? OR purchases_vendors.name ILIKE ?",
                                            search_term, search_term, search_term, search_term, search_term)
    end

    # Include necessary associations for display
    stock_transfers = stock_transfers.includes(:origin_warehouse, :destination_warehouse, :user, :customer_user, :transportista, :vendor)

    # Get total count before pagination for recordsTotal
    total_count = is_adjustment ?
                  StockTransfer.where(is_adjustment: true).count :
                  StockTransfer.where(is_adjustment: false).count

    # Get filtered count before pagination for recordsFiltered
    filtered_count = stock_transfers.count

    # Apply sorting
    if params[:order].present?
      order_column = params[:order]["0"][:column].to_i
      direction = params[:order]["0"][:dir] == "desc" ? "DESC" : "ASC"

      case order_column
      when 0
        stock_transfers = stock_transfers.reorder(Arel.sql("stock_transfers.custom_id #{direction}"))
      when 1
        stock_transfers = stock_transfers.joins(:user).reorder(Arel.sql("users.name #{direction}"))
      when 2
        # Origin column - needs special handling for vendor or warehouse
        stock_transfers = stock_transfers.left_joins(:vendor, :origin_warehouse)
                                        .reorder(Arel.sql("COALESCE(purchases_vendors.name, warehouses.name) #{direction}"))
      when 3
        # Destination column - needs special handling for customer or warehouse
        stock_transfers = stock_transfers.left_joins(:customer_user, :destination_warehouse)
                                        .reorder(Arel.sql("COALESCE(users.name, destination_warehouses.name) #{direction}"))
      when 4
        # Total products
        stock_transfers = stock_transfers.reorder(Arel.sql("(SELECT COUNT(*) FROM stock_transfer_lines WHERE stock_transfer_lines.stock_transfer_id = stock_transfers.id) #{direction}"))
      when 5
        # Transfer date
        stock_transfers = stock_transfers.reorder(Arel.sql("stock_transfers.transfer_date #{direction}"))
      when 6
        # Transportista
        stock_transfers = stock_transfers.left_joins(:transportista)
                                        .reorder(Arel.sql("transportistas.display_name #{direction}"))
      when 7
        # Status
        stock_transfers = stock_transfers.reorder(Arel.sql("stock_transfers.status #{direction}"))
      when 8
        # Stage
        stock_transfers = stock_transfers.reorder(Arel.sql("stock_transfers.stage #{direction}"))
      else
        stock_transfers = stock_transfers.reorder(id: :desc) # Default sorting
      end
    else
      stock_transfers = stock_transfers.order(id: :desc) # Default sorting
    end

    # Pagination
    stock_transfers = stock_transfers.page(params[:start].to_i / params[:length].to_i + 1).per(params[:length].to_i)

    {
      draw: params[:draw].to_i,
      recordsTotal: total_count,
      recordsFiltered: filtered_count,
      data: stock_transfers.map do |stock_transfer|
        row = [
          stock_transfer.custom_id,
          stock_transfer.user&.name,
          # Origin - vendor or warehouse
          if stock_transfer.vendor_id.present?
            "<span class=\"inline-flex items-center\">Proveedor: #{stock_transfer.vendor&.name}</span>"
          else
            stock_transfer.origin_warehouse&.name || "Inventario Inicial"
          end,
          # Destination - customer or warehouse
          if stock_transfer.customer_user_id.present?
            "<span class=\"inline-flex items-center\">Cliente: #{stock_transfer.customer_user&.name}</span>"
          else
            stock_transfer.destination_warehouse&.name
          end,
          stock_transfer.total_products,
          helpers.friendly_date(current_user, stock_transfer.transfer_date),
          stock_transfer.transportista&.display_name,
          stock_transfer.translated_status,
          helpers.translated_stage(stock_transfer.stage)
        ]

        # Add guia column if enabled
        if $global_settings[:show_sunat_guia_for_stock_transfers]
          row << (stock_transfer.guia.present? ? stock_transfer.guia : "")
        end

        # Add delivery action column
        delivery_action = ""
        if stock_transfer.pending?
          if $global_settings[:stock_transfers_have_in_transit_step]
            if stock_transfer.origin_warehouse_id == @current_warehouse&.id || current_user.any_admin_or_supervisor?
              if stock_transfer.customer_user_id.present?
                delivery_action = "<a href=\"#{Rails.application.routes.url_helpers.set_to_in_transit_admin_stock_transfer_path(stock_transfer)}\" class=\"btn btn-secondary\" data-turbo-method=\"patch\">Entregar a Cliente</a>"
              else
                delivery_action = "<a href=\"#{Rails.application.routes.url_helpers.set_to_in_transit_admin_stock_transfer_path(stock_transfer)}\" class=\"btn btn-secondary\" data-turbo-method=\"patch\">Entregar a Transportista</a>"
              end
            else
              delivery_action = "Pendiente en Origen"
            end
          else
            if stock_transfer.origin_warehouse_id == @current_warehouse&.id || current_user.any_admin_or_supervisor?
              if stock_transfer.customer_user_id.present?
                delivery_action = "<a href=\"#{Rails.application.routes.url_helpers.initiate_receive_admin_stock_transfer_path(stock_transfer)}\" class=\"btn btn-primary\" data-turbo-method=\"get\">Entregar a Cliente</a>"
              else
                delivery_action = "<a href=\"#{Rails.application.routes.url_helpers.initiate_receive_admin_stock_transfer_path(stock_transfer)}\" class=\"btn btn-primary\" data-turbo-method=\"get\">Entregar a Destino</a>"
              end
            else
              delivery_action = "Pendiente en Origen"
            end
          end
        elsif stock_transfer.in_transit?
          if stock_transfer.destination_warehouse_id == @current_warehouse&.id || current_user.any_admin_or_supervisor?
            delivery_action = "<a href=\"#{Rails.application.routes.url_helpers.initiate_receive_admin_stock_transfer_path(stock_transfer)}\" class=\"btn btn-primary\" data-turbo-method=\"get\">Recibir Transferencia</a>"
          else
            delivery_action = "Por Recibir en Destino"
          end
        end

        row << delivery_action

        # Add actions column
        actions = []

        if is_adjustment
          actions << "<a href=\"#{Rails.application.routes.url_helpers.admin_stock_transfer_path(stock_transfer)}\" class=\"btn-icon\"><svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" fill=\"currentColor\" class=\"bi bi-eye\" viewBox=\"0 0 16 16\"><path d=\"M16 8s-3-5.5-8-5.5S0 8 0 8s3 5.5 8 5.5S16 8 16 8zM1.173 8a13.133 13.133 0 0 1 1.66-2.043C4.12 4.668 5.88 3.5 8 3.5c2.12 0 3.879 1.168 5.168 2.457A13.133 13.133 0 0 1 14.828 8c-.058.087-.122.183-.195.288-.335.48-.83 1.12-1.465 1.755C11.879 11.332 10.119 12.5 8 12.5c-2.12 0-3.879-1.168-5.168-2.457A13.134 13.134 0 0 1 1.172 8z\"/><path d=\"M8 5.5a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5zM4.5 8a3.5 3.5 0 1 1 7 0 3.5 3.5 0 0 1-7 0z\"/></svg></a>"
          if current_user.any_admin_or_supervisor? && stock_transfer.may_finish_transfer?
            actions << "<a href=\"#{Rails.application.routes.url_helpers.adjustment_stock_transfer_admin_confirm_admin_stock_transfer_path(stock_transfer)}\" class=\"btn-icon\" data-turbo-method=\"post\"><svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" fill=\"currentColor\" class=\"bi bi-check\" viewBox=\"0 0 16 16\"><path d=\"M10.97 4.97a.75.75 0 0 1 1.07 1.05l-3.99 4.99a.75.75 0 0 1-1.08.02L4.324 8.384a.75.75 0 1 1 1.06-1.06l2.094 2.093 3.473-4.425a.267.267 0 0 1 .02-.022z\"/></svg></a>"
          end
        else
          if current_user.any_admin_or_supervisor?
            actions << "<a href=\"#{Rails.application.routes.url_helpers.admin_stock_transfer_path(stock_transfer)}\" class=\"btn-icon\"><svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" fill=\"currentColor\" class=\"bi bi-eye\" viewBox=\"0 0 16 16\"><path d=\"M16 8s-3-5.5-8-5.5S0 8 0 8s3 5.5 8 5.5S16 8 16 8zM1.173 8a13.133 13.133 0 0 1 1.66-2.043C4.12 4.668 5.88 3.5 8 3.5c2.12 0 3.879 1.168 5.168 2.457A13.133 13.133 0 0 1 14.828 8c-.058.087-.122.183-.195.288-.335.48-.83 1.12-1.465 1.755C11.879 11.332 10.119 12.5 8 12.5c-2.12 0-3.879-1.168-5.168-2.457A13.134 13.134 0 0 1 1.172 8z\"/><path d=\"M8 5.5a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5zM4.5 8a3.5 3.5 0 1 1 7 0 3.5 3.5 0 0 1-7 0z\"/></svg></a>"
            actions << "<a href=\"#{Rails.application.routes.url_helpers.edit_admin_stock_transfer_path(stock_transfer)}\" class=\"btn-icon\"><svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" fill=\"currentColor\" class=\"bi bi-pencil\" viewBox=\"0 0 16 16\"><path d=\"M12.146.146a.5.5 0 0 1 .708 0l3 3a.5.5 0 0 1 0 .708l-10 10a.5.5 0 0 1-.168.11l-5 2a.5.5 0 0 1-.65-.65l2-5a.5.5 0 0 1 .11-.168l10-10zM11.207 2.5 13.5 4.793 14.793 3.5 12.5 1.207 11.207 2.5zm1.586 3L10.5 3.207 4 9.707V10h.5a.5.5 0 0 1 .5.5v.5h.5a.5.5 0 0 1 .5.5v.5h.293l6.5-6.5zm-9.761 5.175-.106.106-1.528 3.821 3.821-1.528.106-.106A.5.5 0 0 1 5 12.5V12h-.5a.5.5 0 0 1-.5-.5V11h-.5a.5.5 0 0 1-.468-.325z\"/></svg></a>"
            actions << "<a href=\"#{Rails.application.routes.url_helpers.admin_stock_transfer_path(stock_transfer)}\" class=\"btn-icon\" data-turbo-method=\"delete\" data-turbo-confirm=\"¿Estás seguro?\"><svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" fill=\"currentColor\" class=\"bi bi-trash\" viewBox=\"0 0 16 16\"><path d=\"M5.5 5.5A.5.5 0 0 1 6 6v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5zm2.5 0a.5.5 0 0 1 .5.5v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5zm3 .5a.5.5 0 0 0-1 0v6a.5.5 0 0 0 1 0V6z\"/><path fill-rule=\"evenodd\" d=\"M14.5 3a1 1 0 0 1-1 1H13v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V4h-.5a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1H6a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1h3.5a1 1 0 0 1 1 1v1zM4.118 4 4 4.059V13a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1V4.059L11.882 4H4.118zM2.5 3V2h11v1h-11z\"/></svg></a>"
            actions << "<a href=\"#{Rails.application.routes.url_helpers.admin_stock_transfer_path(stock_transfer, format: :pdf)}\" class=\"btn-icon\"><svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" fill=\"currentColor\" class=\"bi bi-printer\" viewBox=\"0 0 16 16\"><path d=\"M2.5 8a.5.5 0 1 0 0-1 .5.5 0 0 0 0 1z\"/><path d=\"M5 1a2 2 0 0 0-2 2v2H2a2 2 0 0 0-2 2v3a2 2 0 0 0 2 2h1v1a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2v-1h1a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-1V3a2 2 0 0 0-2-2H5zM4 3a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v2H4V3zm1 5a2 2 0 0 0-2 2v1H2a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v3a1 1 0 0 1-1 1h-1v-1a2 2 0 0 0-2-2H5zm7 2v3a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-3a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1z\"/></svg></a>"
          else
            actions << "<a href=\"#{Rails.application.routes.url_helpers.edit_admin_stock_transfer_path(stock_transfer)}\" class=\"btn-icon\"><svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" fill=\"currentColor\" class=\"bi bi-pencil\" viewBox=\"0 0 16 16\"><path d=\"M12.146.146a.5.5 0 0 1 .708 0l3 3a.5.5 0 0 1 0 .708l-10 10a.5.5 0 0 1-.168.11l-5 2a.5.5 0 0 1-.65-.65l2-5a.5.5 0 0 1 .11-.168l10-10zM11.207 2.5 13.5 4.793 14.793 3.5 12.5 1.207 11.207 2.5zm1.586 3L10.5 3.207 4 9.707V10h.5a.5.5 0 0 1 .5.5v.5h.5a.5.5 0 0 1 .5.5v.5h.293l6.5-6.5zm-9.761 5.175-.106.106-1.528 3.821 3.821-1.528.106-.106A.5.5 0 0 1 5 12.5V12h-.5a.5.5 0 0 1-.5-.5V11h-.5a.5.5 0 0 1-.468-.325z\"/></svg></a>"
            actions << "<a href=\"#{Rails.application.routes.url_helpers.admin_stock_transfer_path(stock_transfer)}\" class=\"btn-icon\"><svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" fill=\"currentColor\" class=\"bi bi-eye\" viewBox=\"0 0 16 16\"><path d=\"M16 8s-3-5.5-8-5.5S0 8 0 8s3 5.5 8 5.5S16 8 16 8zM1.173 8a13.133 13.133 0 0 1 1.66-2.043C4.12 4.668 5.88 3.5 8 3.5c2.12 0 3.879 1.168 5.168 2.457A13.133 13.133 0 0 1 14.828 8c-.058.087-.122.183-.195.288-.335.48-.83 1.12-1.465 1.755C11.879 11.332 10.119 12.5 8 12.5c-2.12 0-3.879-1.168-5.168-2.457A13.134 13.134 0 0 1 1.172 8z\"/><path d=\"M8 5.5a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5zM4.5 8a3.5 3.5 0 1 1 7 0 3.5 3.5 0 0 1-7 0z\"/></svg></a>"
          end
        end

        row << actions.join(" ")

        row
      end
    }
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
    params.require(:stock_transfer).permit(:origin_warehouse_id, :destination_warehouse_id, :guia, :transfer_date, :comments, :is_adjustment, :adjustment_type, :create_guia, :transportista_id, :to_customer, :customer_user_id, :from_vendor, :vendor_id, stock_transfer_lines_attributes: [ :id, :product_id, :quantity, :received_quantity, :_destroy ])
  end
end
