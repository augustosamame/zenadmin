class Admin::ProductsStockController < Admin::AdminController
  include ActionView::Helpers::NumberHelper
  before_action :set_warehouses

  def index
    respond_to do |format|
      format.html do
        @products = Product
          .includes(:media, :warehouse_inventories, :tags)
          .left_joins(:warehouse_inventories)
          .where("warehouse_inventories.warehouse_id = ? OR warehouse_inventories.warehouse_id IS NULL", @current_warehouse.id)
          .select("products.*, COALESCE(warehouse_inventories.stock, 0) AS stock")
          .order(id: :desc)

        if @products.size > 1000
          @datatable_options = "server_side:true;state_save:true;resource_name:'Product';sort_0_asc;#{current_user.any_admin? ? '' : 'create_button:false;'}"
        else
          @datatable_options = "resource_name:'Product';sort_0_asc;state_save:true;#{current_user.any_admin? ? '' : 'create_button:false;'}"
        end
      end

      format.json do
        render json: datatable_json
      end
    end
  end

  private

  def set_warehouses
    # Exclude the current warehouse from the list of warehouses
    @warehouses = Warehouse.where.not(id: @current_warehouse.id).order(:name)
  end

  def datatable_json
    products = Product.all

    # Apply search filter
    if params[:search][:value].present?
      products = products.search_by_custom_id_and_name(params[:search][:value])
    end

    # Apply sorting
    if params[:order].present?
      order_by = case params[:order]["0"][:column].to_i
      when 0 then "custom_id"
      when 2 then "name"
      when 3 then "price_cents"
      when 4 then "status"
      when 5
        # For the stock column, join the warehouse_inventories table and order by stock
        products = products.joins(:warehouse_inventories).where(warehouse_inventories: { warehouse_id: @current_warehouse.id })
        "warehouse_inventories.stock"
      else "name"
      end
      direction = params[:order]["0"][:dir] == "desc" ? "desc" : "asc"
      products = products.reorder("#{order_by} #{direction}")
    end

    # Pagination
    products = products.page(params[:start].to_i / params[:length].to_i + 1).per(params[:length].to_i)

    # Get all warehouses for stock columns
    warehouses = Warehouse.all.order(:name)

    # Return the data in the format expected by DataTables
    {
      draw: params[:draw].to_i,
      recordsTotal: Product.count,
      recordsFiltered: products.total_count,
      data: products.map do |product|
        row = [
          product.custom_id,
          product_image_tag_thumb(product),
          product.name,
          format_currency(product.price),
          product.status == 0 ? "Active" : "Inactive"
        ]
        
        # Add stock for current warehouse
        row << product.stock(@current_warehouse)
        
        # Add stock for each warehouse
        warehouses.each do |warehouse|
          row << product.stock(warehouse)
        end
        
        # Add total stock across all warehouses
        total_stock = product.warehouse_inventories.sum(:stock)
        row << total_stock
        
        row
      end
    }
  end

  def product_image_tag_thumb(product)
    if product.image.present?
      ActionController::Base.helpers.image_tag(product.smart_image(:thumb), alt: product.name, class: "rounded-full sm:w-10 w-14 sm:h-10 h-14")
    else
      "No Image" # Or an alternative placeholder
    end
  end
end
