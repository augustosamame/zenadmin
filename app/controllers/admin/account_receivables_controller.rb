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
      @unapplied_payments = Payment.unapplied.includes([ :cashier_shift ]).where(user_id: params[:user_id]).order(id: :desc)
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

      # Check if customer has any account receivables or payments
      @has_transactions = @account_receivables.any? || @unapplied_payments.any? || @applied_payments.any?
    else
      raise "User ID is required"
    end

    @datatable_options = "resource_name:'AccountReceivable';sort_0_desc;create_button:false;"
  end

  def show
    @account_receivable = AccountReceivable.find(params[:id])
  end

  def payments_calendar
    if current_user.any_admin? && params[:location_id].present?
      @location = Location.find(params[:location_id])
    else
      @location = @current_location
    end
    @account_receivables = AccountReceivable
        .includes(:order)
        .joins(order: :location)
        .where(orders: { location_id: @location&.id })
        .where("account_receivables.due_date >= ?", 30.days.ago)
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

  def create_initial_balance
    @user = User.find(params[:user_id])
    amount = params[:amount].to_f

    # Find or create a special cashier and cashier shift for initial balances
    initial_balance_cashier = Cashier.find_by(name: "Caja Balance Inicial")

    if initial_balance_cashier.nil?
      # Create a special cashier for initial balances
      initial_balance_cashier = Cashier.create!(
        name: "Caja Balance Inicial",
        location: Location.first
      )
    end

    # Find or create an open cashier shift for the initial balance cashier
    initial_balance_shift = CashierShift.where(cashier_id: initial_balance_cashier.id, status: :open).first

    if initial_balance_shift.nil?
      # Create a new open cashier shift
      initial_balance_shift = CashierShift.create!(
        cashier_id: initial_balance_cashier.id,
        date: Date.current,
        total_sales_cents: 0,
        status: :open,
        opened_by_id: current_user.id,
        opened_at: Time.current
      )
    end

    ActiveRecord::Base.transaction do
      if amount > 0
        # Create an account receivable for positive balance (customer owes money)
        account_receivable = AccountReceivable.new(
          user: @user,
          amount: amount,
          currency: "PEN",
          status: :pending,
          order_id: nil,
          payment_id: nil,
          description: "Saldo inicial",
          due_date: params[:due_date].present? ? Time.zone.parse(params[:due_date]).change(hour: 12) : nil
        )

        if account_receivable.save
            flash[:notice] = "Saldo inicial por cobrar creado exitosamente"
        else
          flash[:alert] = "Error al crear el saldo inicial: #{account_receivable.errors.full_messages.join(', ')}"
          raise ActiveRecord::Rollback
        end
      elsif amount < 0
        # Create a payment for negative balance (customer has credit)
        payment = Payment.new(
          user: @user,
          amount: amount.abs,
          currency: "PEN",
          status: :paid,
          payment_method: PaymentMethod.find_by(name: "cash") || PaymentMethod.first,
          payment_date: Time.current,
          cashier_shift: initial_balance_shift,
          description: "Saldo inicial a favor",
          comment: "Saldo inicial a favor del cliente"
        )

        if payment.save
            flash[:notice] = "Saldo inicial a favor creado exitosamente"
        else
          flash[:alert] = "Error al crear el saldo inicial: #{payment.errors.full_messages.join(', ')}"
          raise ActiveRecord::Rollback
        end
      else
        flash[:alert] = "El monto debe ser diferente de cero"
        raise ActiveRecord::Rollback
      end
    end

    redirect_to admin_account_receivables_path(user_id: @user.id)
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
