class Admin::Inventory::ProductMinMaxStocksController < Admin::AdminController
  def index
    @warehouse = @current_warehouse

    @products = Product.active
                      .includes(:warehouse_inventories, :media)
                      .left_joins(:product_min_max_stocks)
                      .where("product_min_max_stocks.warehouse_id = ? OR product_min_max_stocks.warehouse_id IS NULL", @warehouse.id)
                      .select("products.*, COALESCE(product_min_max_stocks.min_stock, 0) as min_stock, COALESCE(product_min_max_stocks.max_stock, 0) as max_stock")
                      .order(min_stock: :desc, id: :desc)

    if @products.size > 1000
      @datatable_options = "server_side:true;resource_name:'ProductMinMaxStock';sort_0_asc;"
    else
      @datatable_options = "resource_name:'ProductMinMaxStock';sort_0_asc;"
    end
  end

  def create
    @warehouse = Warehouse.find(params[:warehouse_id])

    ActiveRecord::Base.transaction do
      params[:min_max_stocks].each do |stock_params|
        next if stock_params[:min_stock].blank? && stock_params[:max_stock].blank?

        product_id = stock_params[:product_id]
        min_max_stock = ProductMinMaxStock.find_or_initialize_by(
          product_id: product_id,
          warehouse_id: @warehouse.id
        )

        min_max_stock.update!(
          min_stock: stock_params[:min_stock],
          max_stock: stock_params[:max_stock]
        )

        # Clear existing period multipliers if new ones are present
        if stock_params[:period_multipliers].present?
          min_max_stock.product_min_max_period_multipliers.destroy_all

          stock_params[:period_multipliers].each do |multiplier|
            next if multiplier[:year_month_period].blank? || multiplier[:multiplier].blank?

            min_max_stock.product_min_max_period_multipliers.create!(
              year_month_period: multiplier[:year_month_period],
              multiplier: multiplier[:multiplier]
            )
          end
        end
      end
    end

    redirect_to admin_inventory_product_min_max_stocks_path(warehouse_id: @warehouse.id),
                notice: "Stock mínimo y máximo actualizado correctamente"
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = "Error: #{e.message}"
    render :index, status: :unprocessable_entity
  end
end
