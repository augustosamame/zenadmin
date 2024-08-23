class Admin::ProductsController < Admin::AdminController
  include ActionView::Helpers::NumberHelper

	def index
    respond_to do |format|
      format.html do
        @products = Product.includes([:media]).all
          .joins(:warehouse_inventories)
          .where(warehouse_inventories: { warehouse_id: @current_warehouse.id })
          .select("products.*, warehouse_inventories.stock")
        if @products.size > 5
          @datatable_options = "server_side:true;resource_name:'products';"
        end
      end

      format.json do
        render json: datatable_json
      end
    end
	end

  def search
    if params[:query].blank?
      @products = Product.all
    else
      if params[:query].length <= 50
        @products = Product.search_by_sku_and_name(params[:query])
      else
        @products = []
      end
    end
    render json: @products.map { |product| { id: product.id, sku: product.sku, name: product.name, image: product.image.file_url, price: (product.price_cents / 100), stock: product.stock(@current_warehouse) } }
  end

  private
    # TODO send partials along with JSON so that the HTML structure and classes are exactly like the ones rendered by the HTML datatable
    def datatable_json
      products = Product.all

      # Apply search filter
      if params[:search][:value].present?
        products = products.search_by_sku_and_name(params[:search][:value])
      end

      # Apply sorting
      if params[:order].present?
        order_by = case params[:order]["0"][:column].to_i
        when 0 then "sku"
        when 2 then "name"
        when 3 then "price_cents"
        when 4 then "discounted_price_cents"
        when 5
          # For the stock column, join the warehouse_inventories table and order by stock
          products = products.joins(:warehouse_inventories).where(warehouse_inventories: { warehouse_id: @current_warehouse.id })
          "warehouse_inventories.stock"
        when 6 then "status"
        else "name"
        end
        direction = params[:order]["0"][:dir] == "desc" ? "desc" : "asc"
        products = products.reorder("#{order_by} #{direction}")
      end

      # Pagination
      products = products.page(params[:start].to_i / params[:length].to_i + 1).per(params[:length].to_i)
      # Return the data in the format expected by DataTables
      {
        draw: params[:draw].to_i,
        recordsTotal: Product.count,
        recordsFiltered: products.total_count,
        data: products.map do |product|
          [
            product.sku,
            product_image_tag(product),
            product.name,
            number_to_currency(product.price_cents / 100.0),
            product.discounted_price_cents ? number_to_currency(product.discounted_price_cents / 100.0) : "N/A",
            product.stock(@current_warehouse),
            product.status == 0 ? "Active" : "Inactive",
            render_to_string(partial: "admin/products/actions", formats: [ :html ], locals: { product: product, default_object_options_array: @default_object_options_array })
          ]
        end
      }
    end

    def product_image_tag(product)
      if product.image.present?
        ActionController::Base.helpers.image_tag(product.image.file_url, alt: product.name, class: "rounded-full sm:w-10 w-14 sm:h-10 h-14")
      else
        "No Image" # Or an alternative placeholder
      end
    end
end
