class Admin::PaymentMethodsController < Admin::AdminController


  def index

    respond_to do |format|
      format.html do
        @payment_methods = PaymentMethod.all.active
      end

      format.json do
        render json: PaymentMethod.all.active
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
      render :new
    end
  end

  

  private

  def payment_method_params
    params.require(:payment_method).permit(:name, :description, :status)
  end
end
