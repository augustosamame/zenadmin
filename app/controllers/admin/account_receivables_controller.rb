class Admin::AccountReceivablesController < Admin::AdminController
  before_action :set_account_receivable, only: %i[show]

  def users_index
    authorize! :read, User
    generic_user = User.find_by(email: "generic_customer@devtechperu.com")
    respond_to do |format|
      format.html do
        @users = User.includes(:location, :roles)
                       .where(internal: false)
                       .joins(:roles)
                       .where(roles: { name: "customer" })
                       .where.not(id: generic_user.id)
        @datatable_options = "resource_name:'User';sort_0_desc;create_button:false;"
      end
    end
  end

  def index
    authorize! :read, AccountReceivable
    if params[:user_id].present?
      @user = User.find(params[:user_id])
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

  def payments_calendar
    @account_receivables = AccountReceivable.includes([ :order ]).where("due_date >= ?", 30.days.ago)
                      .order(due_date: :asc)

    @calendar_events = @account_receivables.map do |account_receivable|
      {
        id: account_receivable.id,
        title: "#{account_receivable&.order&.user&.name || account_receivable.user.name}\nS/ #{account_receivable.amount.to_f}",
        start: account_receivable.due_date.to_date.to_s,
        end: (account_receivable.due_date + 1.day).to_date.to_s,
        className: receivable_status_class(account_receivable.status),
        url: admin_account_receivables_path(user_id: account_receivable&.order&.user&.id || account_receivable.user.id),
        extendedProps: {
          amount: account_receivable.amount.to_f,
          customer: account_receivable&.order&.user&.name || account_receivable.user.name,
          status: account_receivable.translated_status
        }
      }
    end
  end

  private

    def set_account_receivable
      @account_receivable = AccountReceivable.find(params[:id])
    end

    def receivable_status_class(status)
      case status
      when "pending"
        "bg-yellow-500 border-yellow-600"
      when "overdue"
        "bg-red-500 border-red-600"
      when "paid"
        "bg-green-500 border-green-600"
      else
        "bg-gray-500 border-gray-600"
      end
    end
end
