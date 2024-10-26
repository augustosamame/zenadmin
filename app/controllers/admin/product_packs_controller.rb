class Admin::ProductPacksController < Admin::AdminController
  before_action :set_product_pack, only: [:show, :edit, :update, :destroy]

  def index
    @product_packs = ProductPack.order(created_at: :desc)
    @datatable_options = "server_side:false;resource_name:'ProductPack';create_button:true;sort_0_desc;"
  end

  def show
  end

  def new
    @product_pack = ProductPack.new
    @product_pack.product_pack_items.build
  end

  def create
    @product_pack = ProductPack.new(product_pack_params)
    if @product_pack.save
      redirect_to admin_product_packs_path, notice: 'Product Pack was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product_pack.update(product_pack_params)
      redirect_to admin_product_packs_path, notice: 'Product Pack was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product_pack.destroy
    redirect_to admin_product_packs_path, notice: 'Product Pack was successfully destroyed.'
  end

  private

  def set_product_pack
    @product_pack = ProductPack.find(params[:id])
  end

  def product_pack_params
    params.require(:product_pack).permit(
      :name, :description, :price, :status,
      product_pack_items_attributes: [:id, :quantity, :_destroy, tag_ids: []]
    )
  end
end