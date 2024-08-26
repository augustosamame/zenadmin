class Admin::UsersController < Admin::AdminController
  before_action :set_user, only: %i[edit update destroy]

  def index
    respond_to do |format|
      format.html do
        @users = User.includes([:location]).where(internal: false).where.not(id: Customer.pluck(:user_id))
        @datatable_options = "resource_name:'User';"
      end
    end
  end

  def new
    @user = User.new
    @user.build_customer
  end

  def create
    @user = User.new(user_params)
    @user.password = SecureRandom.alphanumeric(8)
    if @user.save
      if @user.customer
        redirect_to admin_customers_path, notice: "Cliente fue creado correctamente"
      else
        redirect_to admin_users_path, notice: "Usuario fue creado correctamente"
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to admin_users_path, notice: "User updated successfully"
    else
      render :edit
    end
  end

  def destroy
    if @user.destroy
      redirect_to admin_users_path, notice: "User deleted successfully"
    else
      redirect_to admin_users_path, alert: "User could not be deleted"
    end
  end

  def create_customer
    user = User.new(user_params)
    user.password = SecureRandom.alphanumeric(8)
    if user.save
      render json: user, status: :created
    else
      render json: user.errors, status: :unprocessable_entity
    end
  end

  def sellers
    sellers = User.with_role("seller").where(location_id: params[:location_id] || @current_location&.id)
    render json: sellers.map { |seller| { id: seller.id, name: seller.name } }
  end

  private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:location_id, :status, :email, :phone, :first_name, :last_name, customer_attributes: [ :doc_type, :doc_id, :birthdate ], role_ids: [])
    end
end
