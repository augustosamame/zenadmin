class Admin::CashierTransactionsController < Admin::AdminController
  before_action :initialize_cashier_transaction, only: [ :new, :create ]
  before_action :build_transactable, only: [ :new, :create ]

  def new
    @cashier_shift = CashierShift.find(params[:format])
    @elligible_users = User.with_any_role(:seller, :admin, :super_admin, :supervisor)
    if @cashier_shift.cashier.cashier_type == "bank"
      @elligible_payment_methods = PaymentMethod.where(description: @cashier_shift.cashier.name)
    else
      @elligible_payment_methods = PaymentMethod.all
    end
  end

  def create
    @cashier_shift = if params[:cashier_shift_id].present?
      CashierShift.find(params[:cashier_shift_id])
    else
      @current_cashier_shift
    end
    @cashier_transaction.cashier_shift = @cashier_shift
    @cashier_transaction.currency = "PEN"
    @cashier_transaction.transactable.currency = "PEN" if @cashier_transaction.transactable.present?

    if @cashier_transaction.save
      redirect_to admin_cashier_shift_path(@cashier_transaction.cashier_shift), notice: "Transacción registrada exitosamente."
    else
      load_form_dependencies
      render :new, status: :unprocessable_entity
    end
  end

  private

  def load_form_dependencies
    @cashier_shift = if params[:cashier_shift_id].present?
      CashierShift.find(params[:cashier_shift_id])
    elsif params[:format].present?
      CashierShift.find(params[:format])
    else
      @current_cashier_shift
    end
    @elligible_payment_methods = if @cashier_shift.cashier.cashier_type == "bank"
      PaymentMethod.where(description: @cashier_shift.cashier.name)
    else
      PaymentMethod.all
    end
    @elligible_users = User.with_any_role(:seller, :admin, :super_admin, :supervisor)
  end

  def initialize_cashier_transaction
    @cashier_transaction = CashierTransaction.new(cashier_transaction_params)
    @cashier_transaction.currency ||= "PEN"
    if params[:transactable].present? && params[:transactable][:processor_transacion_id].present?
      @cashier_transaction.processor_transacion_id = params[:transactable][:processor_transacion_id]
    end
  end

  def cashier_transaction_params
    params.fetch(:cashier_transaction, {}).permit(:amount, :transactable_type, :payment_method_id, :currency, :processor_transacion_id)
  end

  def build_transactable
    return unless params[:transactable_type].present?

    transactable_class = safe_constantize(params[:transactable_type])
    return unless transactable_class

    transactable_params = filtered_transactable_params.merge(currency: "PEN")
    @cashier_transaction.transactable ||= transactable_class.new(transactable_params)
    assign_transactable_attributes
  end

  def assign_transactable_attributes
    @cashier_transaction.transactable.tap do |transactable|
      transactable.currency = "PEN"  # Set currency first
      transactable.cashier_shift = @current_cashier_shift
      transactable.amount_cents = @cashier_transaction.amount_cents
      transactable.processor_transacion_id = @cashier_transaction.processor_transacion_id
    end
  end

  def filtered_transactable_params
    case params[:transactable_type]
    when "CashInflow"
      params.fetch(:transactable, {}).permit(
        :processor_transacion_id,
        :received_by_id,
        :description,
        :currency
      )
    when "CashOutflow"
      params.fetch(:transactable, {}).permit(
        :processor_transacion_id,
        :paid_to_id,
        :description,
        :currency
      )
    else
      {}
    end
  end

  private

    def safe_constantize(class_name)
      allowed_classes = [ "Payment", "CashInflow", "CashOutflow" ] # Add all allowed class names
      class_name.in?(allowed_classes) ? class_name.constantize : nil
    end
end
