class Admin::PaymentMethodsController < Admin::AdminController
  before_action :set_payment_method, only: [ :edit, :update, :destroy ]
  def index
    authorize! :read, PaymentMethod
    @datatable_options = "resource_name:'PaymentMethod';create_button:true;"
    if $global_settings[:feature_flag_bank_cashiers_active]
      if $global_settings[:pos_can_create_unpaid_orders]
        if current_user.any_admin?
          @filtered_payment_methods = PaymentMethod.active.order(:payment_method_type, :id)
        else
          @filtered_payment_methods = PaymentMethod.active.where(access: "all").order(:payment_method_type, :id)
        end
      else
        @filtered_payment_methods = PaymentMethod.active.where.not(payment_method_type: "credit").order(:payment_method_type, :id)
      end
    else
      if $global_settings[:pos_can_create_unpaid_orders]
        @filtered_payment_methods = PaymentMethod.active.where.not(payment_method_type: "bank").order(:payment_method_type, :id)
      else
        @filtered_payment_methods = PaymentMethod.active.where.not(payment_method_type: [ "bank", "credit" ]).order(:payment_method_type, :id)
      end
    end
    respond_to do |format|
      format.html do
        @payment_methods = @filtered_payment_methods
      end

      format.json do
        render json: @filtered_payment_methods
      end
    end
  end

  def new
    authorize! :create, PaymentMethod
    @payment_method = PaymentMethod.new
  end

  def create
    authorize! :create, PaymentMethod
    @payment_method = PaymentMethod.new(payment_method_params)
    if @payment_method.save
      redirect_to admin_payment_methods_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize! :update, @payment_method
  end

  def update
    authorize! :update, @payment_method
    if @payment_method.update(payment_method_params)
      redirect_to admin_payment_methods_path, notice: "Payment method was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @payment_method
    @payment_method.destroy
    redirect_to admin_payment_methods_path, notice: "Payment method was successfully deleted."
  end



  private

  def set_payment_method
    @payment_method = PaymentMethod.find(params[:id])
  end

  def payment_method_params
    params.require(:payment_method).permit(:name, :description, :status, :payment_method_type)
  end
end
