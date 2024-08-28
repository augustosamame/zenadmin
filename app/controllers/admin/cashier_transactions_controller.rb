class Admin::CashierTransactionsController < Admin::AdminController
  before_action :initialize_cashier_transaction, only: [ :new, :create ]
  before_action :build_transactable, only: [ :new, :create ]

  def new
  end

  def create
    @cashier_transaction.cashier_shift = @current_cashier_shift

    if @cashier_transaction.save
      redirect_to admin_cashier_shift_path(@cashier_transaction.cashier_shift), notice: "Transaction successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def initialize_cashier_transaction
    @cashier_transaction = CashierTransaction.new(cashier_transaction_params)
  end

  def cashier_transaction_params
    params.fetch(:cashier_transaction, {}).permit(:amount, :transactable_type, :payment_method_id)
  end

  def build_transactable
    return unless params[:transactable_type].present?

    transactable_class = params[:transactable_type].constantize
    @cashier_transaction.transactable ||= transactable_class.new(filtered_transactable_params)
    assign_transactable_attributes
  end

  def assign_transactable_attributes
    @cashier_transaction.transactable.cashier_shift = @current_cashier_shift
    @cashier_transaction.transactable.amount_cents = @cashier_transaction.amount_cents
  end

  def filtered_transactable_params
    params.fetch(params[:transactable_type].underscore, {}).permit(:id, :description, :received_by_id, :paid_to_id, :_destroy)
  end
end
