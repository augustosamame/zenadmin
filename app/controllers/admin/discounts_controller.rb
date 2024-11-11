# app/controllers/admin/discounts_controller.rb
class Admin::DiscountsController < Admin::AdminController
  before_action :set_discount, only: [ :show, :edit, :update, :destroy ]

  def index
    @discounts = Discount.all.includes(:tags)
    if current_user.any_admin_or_supervisor?
      @datatable_options = "resource_name:'Discount';create_button:true;hide_0;sort_0_desc;"
    else
      @datatable_options = "resource_name:'Discount';create_button:false;hide_0;sort_0_desc;"
    end
  end

  def new
    @discount = Discount.new
  end

  def matching_products
    tag_ids = params[:tag_ids].presence || []

    @products = Product.all

    if tag_ids.any?
      @products = @products.joins(:taggings).where(taggings: { tag_id: tag_ids }).distinct
    end

    render partial: "matching_products", locals: { products: @products }
  end

  def create
    @discount = Discount.new(discount_params)
    if @discount.save
      create_or_update_filters
      @discount.update_matching_product_ids
      redirect_to admin_discounts_path, notice: "Descuento creado correctamente."
    else
      render turbo_stream: turbo_stream.replace("discount_form", partial: "form", locals: { discount: @discount })
    end
  end

  def show
  end

  def edit
  end

  def update
    if @discount.update(discount_params)
      create_or_update_filters
      @discount.update_matching_product_ids
      redirect_to admin_discounts_path, notice: "Descuento actualizado correctamente."
    else
      render turbo_stream: turbo_stream.replace("discount_form", partial: "form", locals: { discount: @discount })
    end
  end

  def destroy
    @discount.destroy
    redirect_to admin_discounts_path, notice: "Descuento eliminado correctamente."
  end

  private

  def set_discount
    @discount = Discount.find(params[:id])
  end

  def discount_params
    params.require(:discount).permit(:name, :discount_type, :discount_percentage, :discount_fixed_amount, :group_discount_percentage_off, :group_discount_payed_quantity, :group_discount_free_quantity, :start_datetime, :end_datetime, :status)
  end

  def create_or_update_filters
    @discount.discount_filters.destroy_all

    if params[:tag_ids].present?
      params[:tag_ids].each do |tag_id|
        @discount.discount_filters.create(filterable_type: "Tag", filterable_id: tag_id)
      end
    end
  end
end
