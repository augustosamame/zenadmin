class Admin::UsersController < Admin::AdminController
  before_action :set_user, only: %i[edit update destroy update_contact_info loyalty_info]

  def index
    respond_to do |format|
      format.html do
        # @users = User.includes([ :location ]).where(internal: false).where.not(id: Customer.pluck(:user_id))
        non_internal_users = User.includes(:location, :roles)
                         .where(internal: false)
                         .where.not(id: Customer.pluck(:user_id))

        # Fetch internal users with seller role
        internal_sellers = User.includes(:location, :roles)
                       .where(internal: true)
                       .joins(:roles)
                       .where(roles: { name: "seller" })
                       .where.not(id: Customer.pluck(:user_id))

        # Combine the results
        @users = (non_internal_users + internal_sellers).uniq
        @datatable_options = "resource_name:'User';sort_0_desc;"
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
      register_face_with_aws(@user)
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
      register_face_with_aws(@user)
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
    sellers = User.with_role("seller").where(internal: false, location_id: params[:location_id] || @current_location&.id)
    supervisors = User.with_role("supervisor")

    users = (sellers + supervisors).uniq

    render json: users.map { |user| { id: user.id, name: user.name } }
  end

  def loyalty_info
    if @user.email == "generic_customer@devtechperu.com"
      render json: nil
    else
      loyalty_service = Services::Sales::LoyaltyTierService.new(@user)
      render json: loyalty_service.loyalty_info
    end
  end

  def update_contact_info
    if @user.update(user_params)
      if params[:order_to_email].present?
        @order = Order.find(params[:order_to_email])
        Services::Sales::OrderInvoiceService.new(@order).send_invoice_email
      end
      render json: @user
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:location_id, :status, :email, :phone, :first_name, :last_name, :photo, customer_attributes: [ :doc_type, :doc_id, :birthdate ], role_ids: [])
    end

    def register_face_with_aws(user)
      return unless user.photo.present?

      client = Aws::Rekognition::Client.new(
        region: 'us-east-1',
        credentials: Aws::Credentials.new(
          ENV['AWS_ACCESS_KEY_ID'],
          ENV['AWS_SECRET_ACCESS_KEY']
        )
      )
      photo_data = user.photo.split(',')[1] # Remove data URL prefix
      image_bytes = Base64.decode64(photo_data)

      begin
        response = client.index_faces({
          collection_id: "sellers_faces",
          image: { bytes: image_bytes },
          external_image_id: user.id.to_s,
          detection_attributes: ["ALL"]
        })
        # You might want to save the face_id from the response to the user record
        if response.face_records.any?
          user.update(face_id: response.face_records.first.face.face_id)
        end
      rescue Aws::Rekognition::Errors::ServiceError => e
        Rails.logger.error "Error indexing face: #{e.message}"
        # Handle the error appropriately
      end
    end
end
