class Admin::UsersController < Admin::AdminController
  def index
    users = User.all
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
    sellers = User.with_role("seller")
    render json: sellers.map { |seller| { id: seller.id, name: seller.name } }
  end

  private

  def user_params
    params.require(:user).permit(:email, :phone, :first_name, :last_name, customer_attributes: [ :doc_type, :doc_id ])
  end
end
