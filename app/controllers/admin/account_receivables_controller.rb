class Admin::AccountReceivablesController < Admin::AdminController
  before_action :set_account_receivable, only: %i[show]

  def users_index
    authorize! :read, User
    respond_to do |format|
      format.html do
        @users = User.includes(:location, :roles)
                       .where(internal: false)
                       .joins(:roles)
                       .where(roles: { name: "customer" })

        @datatable_options = "resource_name:'User';sort_0_desc;create_button:false;"
      end
    end
  end

  def index
    authorize! :read, AccountReceivable
    if params[:user_id].present?
      @account_receivables = AccountReceivable.where(user_id: params[:user_id])
      @unapplied_payments = Payment.includes([ :cashier_shift ]).where(user_id: params[:user_id], account_receivable_id: nil, status: "paid").order(id: :desc)
      @applied_payments = Payment.where(payable_type: "Order")
                                .joins("INNER JOIN orders ON orders.id = payments.payable_id")
                                .where(orders: { user_id: params[:user_id], is_credit_sale: true })
                                .where.not(account_receivable_id: nil)
      @total_sales = Order.where(user_id: params[:user_id]).sum(:total_price_cents) / 100.0
      @total_credit_sales = @account_receivables.sum(:amount_cents) / 100.0
      @total_paid = (@applied_payments.sum(:amount_cents) / 100.0) + (@unapplied_payments.sum(:amount_cents) / 100.0)
      @total_unapplied_payments = @unapplied_payments.sum(:amount_cents) / 100.0
      @total_pending_previous_period = 0
      @total_pending = @account_receivables.sum(:amount_cents) / 100.0 - @total_paid + @total_pending_previous_period
    else
      raise "User ID is required"
    end

    @datatable_options = "resource_name:'AccountReceivable';sort_0_desc;create_button:false;"
  end

  def show
    @account_receivable = AccountReceivable.find(params[:id])
  end

  private

    def set_account_receivable
      @account_receivable = AccountReceivable.find(params[:id])
    end
end
