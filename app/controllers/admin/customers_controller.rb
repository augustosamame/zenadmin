class Admin::CustomersController < Admin::AdminController
  def index
    respond_to do |format|
      format.html do
        @users = User.includes([ :customer ]).where(internal: false).with_role("customer")
        @datatable_options = "resource_name:'Customer';hide_0;sort_0_desc;"
      end
      format.json do
        @customers = User.with_role("customer")
        # query for customers modal in pos
        render json: @customers.select(:id, :first_name, :last_name, :email, :phone)
      end
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("switchable-container", partial: "admin/customers/table", locals: { customers: Customer.all })
      end
    end
  end


  def new
    @user = User.new
    @user.build_customer

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("switchable-container", partial: "admin/customers/form", locals: { in_modal: params[:in_modal] })
      end
    end
  end

  def create
    @user = User.new(user_params)
    @user.add_role("customer")
    @user.password ||= SecureRandom.alphanumeric(8)
    respond_to do |format|
      if @user.save
        format.turbo_stream { render turbo_stream: [
          turbo_stream.replace("switchable-container", partial: "admin/customers/table", locals: { customers: Customer.all, in_modal: params[:in_modal] }),
          turbo_stream.append("switchable-container", 
            "<script>document.dispatchEvent(new CustomEvent('customer-form-result', { detail: { success: true } }))</script>"
        )
        ]
      }
      else
        format.html { render :new }
        format.turbo_stream { 
          render turbo_stream: [
            turbo_stream.replace(
              "switchable-container", 
              partial: "admin/customers/form",
              locals: { in_modal: params[:in_modal], user: @user }
            ),
          turbo_stream.append("switchable-container", 
            "<script>document.dispatchEvent(new CustomEvent('customer-form-result', { detail: { success: false } }))</script>"
          )
          ]
        }
      end
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

  private

    def user_params
      params.require(:user).permit(:first_name, :last_name, :email, :phone, customer_attributes: [:id, :doc_type, :doc_id, :birthdate, :_destroy])
    end

    def customer_params
      params.require(:user).require(:customer_attributes).permit(:doc_type, :doc_id, :birthdate)
    end
end
