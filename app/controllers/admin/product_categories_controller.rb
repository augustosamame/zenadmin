class Admin::ProductCategoriesController < Admin::AdminController
  before_action :set_product_category, only: [ :edit, :update, :destroy ]

  def index
    @product_categories = ProductCategory.includes(:parent).all
    @datatable_options = "resource_name:'ProductCategory';create_button:true;hide_0;sort_0_desc;"
  end

  def new
    @product_category = ProductCategory.new
  end

  def edit
  end

  def create
    @product_category = ProductCategory.new(product_category_params)
    if @product_category.save
      redirect_to admin_product_categories_path, notice: "La categoría fue creada exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @product_category.update(product_category_params)
      redirect_to admin_product_categories_path, notice: "La categoría fue actualizada correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product_category.destroy
    redirect_to admin_product_categories_path, notice: "La categoría fue eliminada exitosamente."
  end

  private

    def set_product_category
      @product_category = ProductCategory.find(params[:id])
    end

    def product_category_params
      params.require(:product_category).permit(:name, :status, :parent_id)
    end
end
