class Admin::LoyaltyTiersController < Admin::AdminController
  before_action :set_loyalty_tier, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize! :read, LoyaltyTier
    @loyalty_tiers = LoyaltyTier.all.includes([ :free_product ]).order(id: :asc)
    @datatable_options = "resource_name:'LoyaltyTier';create_button:true;sort_2_asc;"

    respond_to do |format|
      format.html
    end
  end

  def show
    authorize! :read, @loyalty_tier
  end

  def new
    authorize! :create, LoyaltyTier
    @loyalty_tier = LoyaltyTier.new
  end

  def create
    authorize! :create, LoyaltyTier
    @loyalty_tier = LoyaltyTier.new(loyalty_tier_params)
    if @loyalty_tier.save
      redirect_to admin_loyalty_tiers_path, notice: "Loyalty Tier was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize! :update, @loyalty_tier
  end

  def update
    authorize! :update, @loyalty_tier
    if @loyalty_tier.update(loyalty_tier_params)
      redirect_to admin_loyalty_tiers_path, notice: "Loyalty Tier was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @loyalty_tier
    if @loyalty_tier.destroy
      redirect_to admin_loyalty_tiers_path, notice: "Loyalty Tier was successfully deleted."
    else
      redirect_to admin_loyalty_tiers_path, alert: "Loyalty Tier could not be deleted."
    end
  end

  private

  def set_loyalty_tier
    @loyalty_tier = LoyaltyTier.find(params[:id])
  end

  def loyalty_tier_params
    params.require(:loyalty_tier).permit(:name, :status, :free_product_id, :requirements_orders_count, :requirements_total_amount, :discount_percentage_integer)
  end
end
