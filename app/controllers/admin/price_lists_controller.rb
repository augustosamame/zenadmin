class Admin::PriceListsController < Admin::AdminController
  before_action :set_price_list, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize! :read, PriceList
    @datatable_options = "server_side:false;state_save:true;resource_name:'PriceList';sort_0_asc;create_button:true;"
    @price_lists = PriceList.all.order(:name)

    respond_to do |format|
      format.html
      format.json do
        render json: @price_lists
      end
    end
  end

  def show
    authorize! :read, @price_list
    
    respond_to do |format|
      format.html { redirect_to edit_admin_price_list_path(@price_list) }
      format.json { render json: @price_list }
    end
  end

  def new
    authorize! :create, PriceList
    @price_list = PriceList.new
  end

  def create
    authorize! :create, PriceList
    @price_list = PriceList.new(price_list_params)

    if @price_list.save
      # Create price list items for all products with default price
      Product.all.each do |product|
        @price_list.price_list_items.create(product: product, price: product.price)
      end

      redirect_to admin_price_lists_path, notice: "Lista de precios creada."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize! :update, @price_list
    @products = Product.all.order(:name)
    @price_list_items = @price_list.price_list_items.includes(:product)
    @price_list_items_datatable_options = "search_input:true;paging:true;info:true;page_length:25;sort_0_asc;resource_name:'PriceListItem';create_button:false;"
  end

  def update
    authorize! :update, @price_list

    if @price_list.update(price_list_params)
      # Update price list items if they are included in the params
      if params[:price_list_items].present?
        params[:price_list_items].each do |item_id, item_params|
          price_list_item = PriceListItem.find(item_id)
          price_list_item.update(price: item_params[:price])
        end
      end

      redirect_to admin_price_lists_path, notice: "Lista de precios actualizada."
    else
      @products = Product.all.order(:name)
      @price_list_items = @price_list.price_list_items.includes(:product)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @price_list
    @price_list.destroy
    redirect_to admin_price_lists_path, notice: "Lista de precios eliminada."
  end

  private

  def set_price_list
    @price_list = PriceList.find(params[:id])
  end

  def price_list_params
    params.require(:price_list).permit(:name, :status)
  end
end
