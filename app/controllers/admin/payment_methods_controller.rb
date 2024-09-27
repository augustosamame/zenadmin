class Admin::PaymentMethodsController < Admin::AdminController
  before_action :set_payment_method, only: [ :edit, :update, :destroy ]
  def index
    @datatable_options = "resource_name:'PaymentMethod';create_button:true;"
    respond_to do |format|
      format.html do
        @payment_methods = PaymentMethod.all.active.order(:id)
      end

      format.json do
        render json: PaymentMethod.all.active.order(:id)
      end
    end
  end

  def new
    @payment_method = PaymentMethod.new
  end

  def create
    @payment_method = PaymentMethod.new(payment_method_params)
    if @payment_method.save
      redirect_to admin_payment_methods_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @payment_method.update(payment_method_params)
      redirect_to admin_payment_methods_path, notice: "Payment method was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @payment_method.destroy
    redirect_to admin_payment_methods_path, notice: "Payment method was successfully deleted."
  end



  private

  def set_payment_method
    @payment_method = PaymentMethod.find(params[:id])
  end

  def payment_method_params
    params.require(:payment_method).permit(:name, :description, :status)
  end
end
