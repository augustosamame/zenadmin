class Admin::ComboProductsController < Admin::AdminController
  before_action :set_combo_product, only: [ :show, :edit, :update, :destroy ]

  def index
    @combo_products = ComboProduct.all.includes(:product_1, :product_2)
    @datatable_options = "resource_name:'ComboProduct';create_button:true;"
  end

  def new
    @combo_product = ComboProduct.new
  end

  def create
    @combo_product = ComboProduct.new(combo_product_params)
    if @combo_product.save
      redirect_to admin_combo_products_path, notice: "El pack fue creado exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    redirect_to admin_combo_products_path
  end

  def destroy
    @combo_product.destroy
    redirect_to admin_combo_products_path, notice: "El pack fue eliminado exitosamente."
  end

  def edit
  end

  def update
    if @combo_product.update(combo_product_params)
      redirect_to admin_combo_products_path, notice: "El pack se actualizó exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_combo_product
    @combo_product = ComboProduct.find(params[:id])
  end

  def combo_product_params
    params.require(:combo_product).permit(:name, :product_1_id, :product_2_id, :qty_1, :qty_2, :normal_price, :price, :status)
  end

  def sanitize_price_params
    [ :normal_price, :price ].each do |price_field|
      if params[:combo_product][price_field].present?
        params[:combo_product][price_field] = params[:combo_product][price_field].gsub(",", ".").to_f
      end
    end
  end
end
