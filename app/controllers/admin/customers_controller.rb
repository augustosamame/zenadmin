class Admin::CustomersController < Admin::AdminController
  def index
    
    respond_to do |format|
      format.html do
        @users = User.includes([:customer]).where(internal: false).with_role("customer")
        @datatable_options = "resource_name:'Customer';"
      end
      format.json do
        @customers = User.with_role("customer")
        #query for customers modal in pos
        render json: @customers.select(:id, :first_name, :last_name, :email, :phone)
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
    @user.add_role("customer")
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
    @user = User.includes(:customer).find(params[:id])
    @customer = @user.customer || @user.build_customer

  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to admin_customers_path, notice: "Cliente actualizado correctamente"
    else
      render :edit
    end
  end

  def destroy
    @user = User.find(params[:id])
    if @user.destroy
      redirect_to admin_customers_path, notice: "Cliente eliminado correctamente"
    else
      redirect_to admin_customers_path, alert: "El cliente no pudo ser eliminado"
    end
  end

  def search_dni
    response = Services::ReniecSunat::ConsultaDniRucPerudevs.consultar_dni(params[:numero])
    if response["mensaje"] && response["mensaje"] == "Encontrado" && response["resultado"].present?
      capitalized_response = response["resultado"].transform_values do |value|
        value.split.map(&:capitalize).join(" ") if value.is_a?(String)
      end
      render json: capitalized_response
    else
      render json: { error: "No se encontraron datos para el DNI ingresado" }
    end
  end
end
