class Admin::ProductsController < Admin::AdminController
  include ActionView::Helpers::NumberHelper

  before_action :set_product, only: %i[edit update destroy]
  before_action :set_product_categories, only: %i[new edit create update]

  def index
    respond_to do |format|
      format.html do
        @products = Product
        .includes(:media, :warehouse_inventories)
        .left_joins(:warehouse_inventories) # Ensures products without inventory are included
        .where("warehouse_inventories.warehouse_id = ? OR warehouse_inventories.warehouse_id IS NULL", @current_warehouse.id)
        .select("products.*, COALESCE(warehouse_inventories.stock, 0) AS stock").order(id: :desc) # Use SQL to fetch stock in one go


        if @products.size > 1000
          @datatable_options = "server_side:true;resource_name:'Product';sort_0_asc;"
        else
          @datatable_options = "resource_name:'Product';sort_0_asc;"
        end
      end

      format.json do
        render json: datatable_json
      end
    end
  end

  def combo_products_show
    @product = Product.select(:id, :name, :price_cents).find(params[:id])
    render json: @product
  end

  def new
    @product = Product.new
  end

  def create
    processed_params = preprocess_media_attributes(product_params)
    # Necessary because the media attributes are not in a nested hash array

    @product = Product.new(processed_params)

    if @product.save
      respond_to do |format|
        format.html { redirect_to admin_products_path, notice: "Product was successfully created." }
        format.turbo_stream { redirect_to admin_products_path } # Ensure Turbo Stream compatibility
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("new_product", partial: "admin/products/form", locals: { product: @product }) }
      end
    end
  end

  def edit
  end

  def update
    processed_params = preprocess_media_attributes(product_params)

    processed_params[:tag_ids] ||= []
    processed_params[:product_category_ids] ||= []

    # TODO refactor
    # Identify which media are to be kept
    # media_ids_to_keep = processed_params[:media_attributes].map { |media| media[:id].to_i }.compact
    # Find media records that should be deleted
    # media_to_delete = @product.media.where.not(id: media_ids_to_keep)

    if @product.update(processed_params)
      # Delete media that are no longer associated with the product
      # media_to_delete.each(&:destroy)

      redirect_to admin_products_path, notice: "Product updated successfully."
    else
      render :edit
    end
  end

  def destroy
    respond_to do |format|
      if @product.destroy
        format.html { redirect_to admin_products_path, notice: "Product was successfully destroyed." }
        # format.turbo_stream { render turbo_stream: turbo_stream.remove(@product) } # Ensure Turbo doesn't re-trigger
      else
        format.html { redirect_to admin_products_path, alert: "Product could not be deleted." }
        # format.turbo_stream { render turbo_stream: turbo_stream.replace(@product, partial: 'product', locals: { product: @product }) }
      end
    end
  end

  def search
    if params[:query].blank?
      @products = Product.active.without_tests.includes(:warehouse_inventories).all
    else
      if params[:query].length <= 50
        @products = Product.active.without_tests.search_by_custom_id_and_name(params[:query])
      else
        @products = []
      end
    end
    render json: @products.map { |product| { id: product.id, custom_id: product.custom_id, name: product.name, image: product.smart_image(:small), price: (product.price_cents / 100), stock: product.stock(@current_warehouse) } }
  end

  private

    def set_product
      @product = Product.find(params[:id])
    end

    def set_product_categories
      @product_categories ||= ProductCategory.includes(:parent).all
    end

    def product_params
      params.require(:product).permit(:custom_id, :file_data, :custom_id, :name, :description, :permalink, :price, :discounted_price, :brand_id, :is_test_product, :status, tag_ids: [], product_category_ids: [],
      media_attributes: [ :id, :file, :file_data, :media_type, :_destroy ])
    end

    def preprocess_media_attributes(params)
      if params[:media_attributes].is_a?(ActionController::Parameters)
        # Transform the hash values into an array
        params[:media_attributes] = params[:media_attributes].values.map do |media_param|
          # Parse `file_data` from a JSON string to a Ruby hash
          media_param["file_data"] = JSON.parse(media_param["file_data"]) if media_param["file_data"].is_a?(String)
          media_param
        end
      end

      params
    end

    # TODO send partials along with JSON so that the HTML structure and classes are exactly like the ones rendered by the HTML datatable
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
            product.custom_id,
            product_image_tag_thumb(product),
            product.name,
            format_currency(product.price),
            product.discounted_price ? format_currency(product.discounted_price) : "N/A",
            product.stock(@current_warehouse),
            product.status == 0 ? "Active" : "Inactive",
            render_to_string(partial: "admin/products/actions", formats: [ :html ], locals: { product: product, warehouse: @current_warehouse, default_object_options_array: @default_object_options_array })
          ]
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
