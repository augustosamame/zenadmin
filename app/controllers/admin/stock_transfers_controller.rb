class Admin::StockTransfersController < Admin::AdminController
  def index
    respond_to do |format|
      format.html do
        @stock_transfers = StockTransfer.all.includes(:origin_warehouse, :destination_warehouse, :user)

        if @stock_transfers.size > 50
          @datatable_options = "server_side:true;resource_name:'StockTransfer';"
        else
          @datatable_options = "resource_name:'StockTransfer';"
        end
      end

      format.json do
        render json: datatable_json
      end
    end
  end

  def show
    @stock_transfer = StockTransfer.find(params[:id])
  end

  def new
    @stock_transfer = StockTransfer.new
    @stock_transfer.user_id = current_user.id
    @stock_transfer.stock_transfer_lines.build
  end

  def create
    @stock_transfer = StockTransfer.new(stock_transfer_params)
    @stock_transfer.user_id = current_user.id
    if @stock_transfer.save
      redirect_to admin_stock_transfers_path, notice: "Stock transfer was successfully created."
    else
      render :new
    end
  end

  def edit
    @stock_transfer = StockTransfer.find(params[:id])
  end

  def update
    @stock_transfer = StockTransfer.find(params[:id])
    if @stock_transfer.update(stock_transfer_params)
      redirect_to admin_stock_transfers_path, notice: "Stock transfer was successfully updated."
    else
      render :edit
    end
  end

  private

  def stock_transfer_params
    params.require(:stock_transfer).permit(:origin_warehouse_id, :destination_warehouse_id, :transfer_date, :comments, stock_transfer_lines_attributes: [ :id, :product_id, :quantity, :_destroy ])
  end
end
