class Admin::InTransitStocksController < Admin::AdminController
  before_action :set_in_transit_stock, only: [ :show, :edit, :update, :destroy ]

  def index
    respond_to do |format|
      format.html do
        @in_transit_stocks = InTransitStock.all.includes(:product,  :user).order(id: :desc)

        if @in_transit_stocks.size > 2000
          @datatable_options = "server_side:true;resource_name:'InTransitStock'; sort_0_desc;create_button:false;"
        else
          @datatable_options = "resource_name:'InTransitStock'; sort_0_desc;create_button:false;"
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
    @in_transit_stock = InTransitStock.new
    @in_transit_stock.user_id = current_user.id
    @in_transit_stock.transfer_date = Time.zone.now
    @in_transit_stock.in_transit_stock_lines.build
  end

  def create
    @in_transit_stock = InTransitStock.new(in_transit_stock_params)
    @in_transit_stock.user_id = current_user.id
    if @in_transit_stock.save
      @in_transit_stock.finish_transfer! if @in_transit_stock.stage == "complete" || @in_transit_stock.origin_warehouse_id.nil? # inventario inicial
      redirect_to admin_in_transit_stocks_path, notice: "La transferencia de Stock se creó correctamente."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @in_transit_stock.update(in_transit_stock_params)
      if @in_transit_stock.stage == "in_transit"
        @in_transit_stock.start_transfer! unless @in_transit_stock.in_transit?
      elsif @in_transit_stock.stage == "complete"
        @in_transit_stock.finish_transfer! unless @in_transit_stock.complete?
      end

      redirect_to admin_stock_transfers_path, notice: "La transferencia de Stock se actualizó correctamente."
    else
      render :edit
    end
  end

  def destroy
    if @in_transit_stock.destroy
      flash[:notice] = "La transferencia de Stock se eliminó correctamente."
    else
      flash[:alert] = "La transferencia de Stock no puede ser eliminada. (#{@in_transit_stock.errors.full_messages.join(', ')})"
    end
    redirect_to admin_stock_transfers_path
  end

  private

  def set_in_transit_stock
    @in_transit_stock = InTransitStock.find(params[:id])
  end

  def in_transit_stock_params
    params.require(:in_transit_stock).permit(:origin_warehouse_id, :destination_warehouse_id, :guia, :transfer_date, :comments, in_transit_stock_lines_attributes: [ :id, :product_id, :quantity, :_destroy ])
  end
end
