class Admin::ProductsController < Admin::AdminController
  include ActionView::Helpers::NumberHelper

  before_action :set_product, only: %i[edit update destroy show]
  before_action :set_product_categories, only: %i[new edit create update]

  def index
    respond_to do |format|
      format.html do
        @products = Product
        .includes(:media, :warehouse_inventories, :tags)
        .left_joins(:warehouse_inventories) # Ensures products without inventory are included
        .where("warehouse_inventories.warehouse_id = ? OR warehouse_inventories.warehouse_id IS NULL", @current_warehouse.id)
        .select("products.*, COALESCE(warehouse_inventories.stock, 0) AS stock")
        .order(id: :desc) # Use SQL to fetch stock in one go


        if @products.size > 1000
          @datatable_options = "server_side:true;state_save:true;resource_name:'Product';sort_0_asc;#{current_user.any_admin? ? '' : 'create_button:false;'}"
        else
          @datatable_options = "resource_name:'Product';sort_0_asc;state_save:true;#{current_user.any_admin? || current_user.has_role?('purchases') ? '' : 'create_button:false;'}"
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

  def show
    @price_list_items = @product.price_list_items.includes(:price_list) if $global_settings[:feature_flag_price_lists]
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

    # Explicitly handle the inafecto attribute
    @product.inafecto = processed_params[:inafecto]

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
    @results = if params[:query].blank?
      # Use a union query for better performance
      base_products = Product.active
                          .without_tests
                          .includes(:warehouse_inventories, :media)
                          .limit(50)
                          .select("id, 'Product' as type, custom_id, name, price_cents, discounted_price_cents")

      base_combos = ComboProduct.active
                              .includes(:product_1, :product_2)
                              .select("id, 'ComboProduct' as type, name, price_cents")

      base_packs = ProductPack.active
                            .includes(product_pack_items: { tags: { products: :media } })
                            .select("id, 'ProductPack' as type, name, price_cents")

      [ base_products, base_combos, base_packs ]
    elsif params[:query].length <= 50
      # Use materialized index for search
      products = Product.active
                      .without_tests
                      .includes(:warehouse_inventories, :media)
                      .search_by_custom_id_and_name(params[:query])
                      .select("id, 'Product' as type, custom_id, name, price_cents, discounted_price_cents")

      combos = ComboProduct.active
                          .includes(:product_1, :product_2)
                          .where("name ILIKE ?", "%#{params[:query]}%")
                          .select("id, 'ComboProduct' as type, name, price_cents")

      packs = ProductPack.active
                        .includes(product_pack_items: { tags: { products: :media } })
                        .where("name ILIKE ?", "%#{params[:query]}%")
                        .select("id, 'ProductPack' as type, name, price_cents")

      [ products, combos, packs ]
    else
      [ [], [], [] ]
    end

    # Fetch all necessary data in parallel
    products, combos, packs = @results

    # Fetch discounts in parallel for products
    product_ids = products.map(&:id)
    applicable_discounts = if product_ids.any?
      Discount.active
            .current
            .type_global
            .where("matching_product_ids && ARRAY[?]::integer[]", product_ids)
            .index_by(&:id)
    else
      {}
    end

    # Find customer if customer_id is provided
    customer = nil
    if params[:customer_id].present? && $global_settings[:feature_flag_price_lists]
      customer = Customer.find_by(user_id: params[:customer_id])
    end

    # Build response using bulk operations
    combined_results = []

    # Process products
    products.each do |product|
      combined_results << product_to_json(product, applicable_discounts, customer)
    end

    # Process combos
    combos.each do |combo|
      combined_results << combo_to_json(combo)
    end

    # Process packs
    packs.each do |pack|
      combined_results << product_pack_to_json(pack)
    end

    render json: combined_results
  end

  def products_matching_tags
    tag_names = params[:tag_names].to_s.split(",")

    @products = Product.joins(:tags)
                      .where(tags: { name: tag_names })
                      .distinct
                      .select(:id, :name, :price_cents)
    render json: @products.map { |p| { id: p.id, name: p.name, price: p.price_cents / 100.0 } }
  end

  def evaluate_group_discount
    if params[:pos_items].present?
      permitted_params = params.require(:pos_items).map do |item|
        item.permit(:product_id, :qty, :price)
      end
      pos_items_array = permitted_params.map(&:to_h)
      current_group_discounts = Discount.active.current.type_group

      total_discount_to_apply = 0
      number_of_qualifying_groups = 0
      applied_discount_counts = Hash.new(0)
      discounted_product_ids = []

      current_group_discounts.each do |group_discount|
        applicable_product_ids = group_discount.matching_product_ids
        qualifying_items = pos_items_array.select do |item|
          applicable_product_ids.include?(item["product_id"].to_i)
        end

        next if qualifying_items.empty?

        expanded_items = qualifying_items.flat_map do |item|
          Array.new(item["qty"].to_i) do
            {
              "product_id" => item["product_id"],
              "price" => item["price"].to_f
            }
          end
        end

        sorted_items = expanded_items.sort_by { |item| -item["price"] }
        payed_quantity = group_discount.group_discount_payed_quantity
        free_quantity = group_discount.group_discount_free_quantity
        percentage_off = group_discount.group_discount_percentage_off

        while sorted_items.size >= payed_quantity
          group = sorted_items.shift(payed_quantity)
          free_items = group.last(payed_quantity - free_quantity)
          free_items_price = free_items.sum { |item| item["price"] }

          # Calculate discount based on percentage_off or full price
          discount_amount = if percentage_off.to_i > 0
                            # Apply percentage discount
                            free_items_price * (percentage_off / 100.0)
          else
                            # Apply full price discount
                            free_items_price
          end

          discounted_product_ids.concat(free_items.map { |item| item["product_id"] })
          total_discount_to_apply += discount_amount
          number_of_qualifying_groups += 1
          applied_discount_counts[group_discount.name] += 1
        end
      end

      if number_of_qualifying_groups > 0
        applied_discount_names = applied_discount_counts.map do |name, count|
          count > 1 ? "#{name} (x#{count})" : name
        end

        render json: {
          number_of_qualifying_groups: number_of_qualifying_groups,
          total_discount_to_apply: total_discount_to_apply,
          applied_discount_names: applied_discount_names,
          discounted_product_ids: discounted_product_ids.uniq
        }
      else
        render json: {
          number_of_qualifying_groups: 0,
          total_discount_to_apply: 0,
          applied_discount_names: nil,
          discounted_product_ids: []
        }
      end
    else
      render json: {
        number_of_qualifying_groups: 0,
        total_discount_to_apply: 0,
        applied_discount_names: nil,
        discounted_product_ids: []
      }
    end
  end

  def bulk_tag
    @products = Product.includes(:tags, :media).all
  end

  def apply_bulk_tags
    product_ids = params[:selected_product_ids].split(",")
    tag_ids = params[:tag_ids]

    if product_ids.present? && tag_ids.present?
      Product.transaction do
        Product.where(id: product_ids).each do |product|
          tag_ids.each do |tag_id|
            product.taggings.find_or_create_by!(tag_id: tag_id)
          end
        end
      end

      flash[:notice] = "Etiquetas aplicadas exitosamente a #{product_ids.size} productos"
    else
      flash[:alert] = "Por favor selecciona productos y etiquetas"
    end

    redirect_to admin_products_path
  end

  def stock
    product = Product.find(params[:id])
    render json: {
      stock: product.stock(@current_warehouse)
    }
  end

  def customer_prices
    if params[:customer_id].blank? || params[:product_ids].blank?
      render json: [], status: :bad_request
      return
    end

    # Check if price lists feature is enabled
    unless $global_settings[:feature_flag_price_lists]
      # Return regular prices if price lists are not enabled
      product_ids = params[:product_ids].split(",").map(&:to_i)
      products = Product.where(id: product_ids)

      result = products.map do |product|
        {
          id: product.id,
          name: product.name,
          price: product.price.to_f,
          price_list_id: nil
        }
      end

      render json: result
      return
    end

    customer = Customer.find_by(user_id: params[:customer_id])
    if customer.nil?
      render json: [], status: :not_found
      return
    end

    product_ids = params[:product_ids].split(",").map(&:to_i)
    products = Product.where(id: product_ids)

    result = products.map do |product|
      price = product.price_for_customer(customer)
      {
        id: product.id,
        name: product.name,
        price: price.to_f,
        price_list_id: customer.price_list_id
      }
    end

    render json: result
  end

  def default_prices
    if params[:product_ids].blank?
      render json: [], status: :bad_request
      return
    end

    product_ids = params[:product_ids].split(",").map(&:to_i)
    products = Product.where(id: product_ids)

    result = products.map do |product|
      {
        id: product.id,
        name: product.name,
        price: product.price.to_f
      }
    end

    render json: result
  end

  private

    def set_product
      @product = Product.find(params[:id])
    end

    def set_product_categories
      @product_categories ||= ProductCategory.includes(:parent).all
    end

    def product_params
      params.require(:product).permit(:custom_id, :file_data, :custom_id, :name, :description, :permalink, :price, :discounted_price, :brand_id, :is_test_product, :status, :inafecto, :unit_of_measure_id, tag_ids: [], product_category_ids: [],
      media_attributes: [ :id, :file, :file_data, :media_type, :_destroy ],
      price_list_items_attributes: [ :id, :price_list_id, :price ])
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

    def product_to_json(product, applicable_discounts, customer = nil)
      # Calculate original price (before any discounts)
      original_price = product.price_cents / 100.0

      # Apply price list pricing if customer is present and has a price list
      if customer.present? && $global_settings[:feature_flag_price_lists]
        customer_price = product.price_for_customer(customer)
        original_price = customer_price.to_f
      end

      # Calculate discounted price (after any discounts)
      discounted_price = original_price

      # Apply global discounts if any
      product_discounts = applicable_discounts.values.select do |discount|
        discount.matching_product_ids.include?(product.id)
      end

      if product_discounts.any?
        # Process discounts with percentage or fixed amount
        percentage_discounts = product_discounts.select { |discount| discount.discount_percentage.present? }
        fixed_amount_discounts = product_discounts.select { |discount| discount.discount_fixed_amount.present? }

        # Apply percentage discount if any
        if percentage_discounts.any?
          max_percentage_discount = percentage_discounts.max_by(&:discount_percentage)
          discounted_price = original_price * (1 - max_percentage_discount.discount_percentage / 100.0)
        end

        # Apply fixed amount discount if any
        if fixed_amount_discounts.any?
          max_fixed_discount = fixed_amount_discounts.max_by(&:discount_fixed_amount)
          discounted_price = original_price - max_fixed_discount.discount_fixed_amount
          # Ensure price doesn't go below zero
          discounted_price = [ discounted_price, 0 ].max
        end
      end

      {
        id: product.id,
        custom_id: product.custom_id,
        name: product.name,
        image: product.smart_image(:small),
        original_price: original_price.to_f,
        discounted_price: discounted_price.to_f,
        price: discounted_price.to_f,
        stock: product.stock(@current_warehouse),
        type: "Product"
      }
    end

    def product_pack_to_json(pack)
      {
        id: pack.id,
        custom_id: "PACK-#{pack.id}",
        name: pack.name,
        image: pack.product_pack_items.first&.tags&.first&.products&.first&.smart_image(:small) || "https://v1-devtech-edukaierp-prod.s3.amazonaws.com/public/default_product_image.jpg",
        price: pack.price.to_f,
        stock: calculate_pack_stock(pack),
        type: "ProductPack",
        pack_details: {
          items: pack.product_pack_items.map do |item|
            {
              quantity: item.quantity,
              tags: item.tags.map(&:name)
            }
          end
        }
      }
    end

    def combo_to_json(combo)
      {
        id: combo.id,
        custom_id: "COMBO-#{combo.id}",
        name: combo.name,
        image: combo.product_1&.smart_image(:small),
        price: combo.price_cents / 100.0,
        stock: combo.stock(@current_warehouse),
        type: "ComboProduct",
        combo_details: {
          normal_price: combo.normal_price_cents / 100.0,
          price: combo.price_cents / 100.0,
          discount: (combo.normal_price_cents - combo.price_cents) / 100.0,
          products: [
            {
              id: combo.product_1&.id,
              custom_id: combo.product_1&.custom_id,
              name: combo.product_1&.name,
              quantity: combo.qty_1,
              regular_price: combo.product_1&.price_cents.to_f / 100.0
            },
            {
              id: combo.product_2&.id,
              custom_id: combo.product_2&.custom_id,
              name: combo.product_2&.name,
              quantity: combo.qty_2,
              regular_price: combo.product_2&.price_cents.to_f / 100.0
            }
          ]
        }
      }
    end

    def calculate_pack_stock(pack)
      pack.product_pack_items.map do |item|
        item.tags&.map do |tag|
          tag.products&.map { |product| product.stock(@current_warehouse) || 0 }&.min
        end&.min
      end&.min || 0
    rescue StandardError => e
      Rails.logger.error "Error calculating pack stock: #{e.message}"
      0
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
