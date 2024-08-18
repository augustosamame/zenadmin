class Admin::ProductsController < ApplicationController
	layout "admin"
  include ActionView::Helpers::NumberHelper

	def index
    @object_options_array = [
      { event_name: "edit", label: "Editar", icon: "pencil-square" },
      { event_name: "delete", label: "Eliminar", icon: "trash" },
    ]
    respond_to do |format|
      format.html do
        @products = Product.all
        if @products.count > 2000
          @datatable_options = "server_side:true"
        end
      end

      format.json do
        render json: datatable_json
      end
    end
	end

  private
    #TODO send partials along with JSON so that the HTML structure and classes are exactly like the ones rendered by the HTML datatable
    def datatable_json
      products = Product.all

      # Apply search filter
      if params[:search][:value].present?
        products = products.where("name ILIKE ? OR permalink ILIKE ?", "%#{params[:search][:value]}%", "%#{params[:search][:value]}%")
      end

      # Apply sorting
      if params[:order].present?
        order_by = case params[:order]['0'][:column].to_i
                  when 0 then 'name'
                  when 1 then 'brand_id'
                  when 2 then 'price_cents'
                  when 3 then 'discounted_price_cents'
                  when 4 then 'available_at'
                  when 5 then 'status'
                  else 'name'
                  end
        direction = params[:order]['0'][:dir] == 'desc' ? 'desc' : 'asc'
        products = products.order("#{order_by} #{direction}")
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
            product.discounted_price_cents ? number_to_currency(product.discounted_price_cents / 100.0) : 'N/A',
            product.available_at ? product.available_at.strftime("%b %d, %Y") : 'N/A',
            product.status == 0 ? 'Active' : 'Inactive',
            render_to_string(partial: 'admin/products/actions', formats: [:html], locals: { product: product, object_options_array: @object_options_array })
          ]
        end
      }
    end

    def product_image_tag(product)
      if product.image.present?
        ActionController::Base.helpers.image_tag(product.image, alt: product.name, class: "rounded-full sm:w-10 w-14 sm:h-10 h-14")
      else
        "No Image" # Or an alternative placeholder
      end
    end

end
