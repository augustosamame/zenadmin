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

        # Precompute balances for all users to avoid N+1 queries
        @user_balances = {}

        # Get all user IDs
        user_ids = @users.pluck(:id)

        # Get all account receivables in one query
        receivables_by_user = AccountReceivable.where(user_id: user_ids)
                                              .group(:user_id)
                                              .sum(:amount_cents)

        # Get all applied payments in one query
        applied_payments_by_user = {}

        # This query gets all payments applied to orders for each user
        applied_payments_query = Payment.where(payable_type: "Order")
                                        .joins("INNER JOIN orders ON orders.id = payments.payable_id")
                                        .where(orders: { user_id: user_ids, is_credit_sale: true })
                                        .where.not(account_receivable_id: nil)
                                        .group("orders.user_id")
                                        .sum(:amount_cents)

        applied_payments_query.each do |user_id, amount|
          applied_payments_by_user[user_id] = amount
        end

        # Get all unapplied payments in one query
        unapplied_payments_by_user = Payment.unapplied
                                           .where(user_id: user_ids)
                                           .group(:user_id)
                                           .sum(:amount_cents)

        @users.each do |user|
          total_receivables = receivables_by_user[user.id] || 0
          total_applied_payments = applied_payments_by_user[user.id] || 0
          total_unapplied_payments = unapplied_payments_by_user[user.id] || 0
          total_pending_previous_period = (user&.account_receivable_initial_balance&.to_f * 100) || 0
          total_payments = total_applied_payments + total_unapplied_payments

          # Calculate balance (receivables - payments)
          @user_balances[user.id] = (total_receivables - total_payments - total_pending_previous_period) / 100.0
        end

        @datatable_options = "resource_name:'User';sort_4_desc;create_button:false;"
      end
    end
  end

  def index
    authorize! :read, AccountReceivable
    if params[:user_id].present?
      @user = User.find(params[:user_id])
      @account_receivables = AccountReceivable.where(user_id: @user.id)
      @unapplied_payments = Payment.unapplied.includes([ :cashier_shift ]).where(user_id: @user.id).order(id: :desc)
      @applied_payments = Payment.where(payable_type: "Order")
                                .joins("INNER JOIN orders ON orders.id = payments.payable_id")
                                .where(orders: { user_id: @user.id, is_credit_sale: true })
                                .where.not(account_receivable_id: nil)
      @total_pending_previous_period = @user.account_receivable_initial_balance.to_f
      @total_sales = Order.where(user_id: @user.id).sum(:total_price_cents) / 100.0
      if @total_pending_previous_period > 0
        @total_credit_sales = (@account_receivables.sum(:amount_cents) / 100.0) - @total_pending_previous_period
        @total_paid = (@applied_payments.sum(:amount_cents) / 100.0) + (@unapplied_payments.sum(:amount_cents) / 100.0)
      else
        @total_credit_sales = @account_receivables.sum(:amount_cents) / 100.0
        @total_paid = (@applied_payments.sum(:amount_cents) / 100.0) + (@unapplied_payments.sum(:amount_cents) / 100.0) - @total_pending_previous_period
      end
      @total_unapplied_payments = @unapplied_payments.sum(:amount_cents) / 100.0
      @total_pending = @total_credit_sales - @total_paid

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

    success = false
    message = ""

    ActiveRecord::Base.transaction do
      # Update the user's initial balance field
      @user.update!(account_receivable_initial_balance: amount)

      if amount > 0
        # Find existing initial balance account receivable or create a new one
        existing_initial_balance = AccountReceivable.find_by(user: @user, description: "Saldo inicial", order_id: nil)

        if existing_initial_balance.present?
          # Update the existing account receivable
          if existing_initial_balance.update(
              amount: amount,
              due_date: params[:due_date].present? ? Time.zone.parse(params[:due_date]).change(hour: 12) : nil
            )
            success = true
            message = "Saldo inicial por cobrar actualizado exitosamente"
            flash[:notice] = message
          else
            message = "Error al actualizar el saldo inicial: #{existing_initial_balance.errors.full_messages.join(', ')}"
            flash[:alert] = message
            raise ActiveRecord::Rollback
          end
        else
          # Create a new account receivable for positive balance (customer owes money)
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
            success = true
            message = "Saldo inicial por cobrar creado exitosamente"
            flash[:notice] = message
          else
            message = "Error al crear el saldo inicial: #{account_receivable.errors.full_messages.join(', ')}"
            flash[:alert] = message
            raise ActiveRecord::Rollback
          end
        end
      elsif amount < 0
        # Find existing initial balance payment or create a new one
        existing_initial_balance = Payment.find_by(user: @user, description: "Saldo inicial a favor")

        if existing_initial_balance.present?
          # Update the existing payment
          if existing_initial_balance.update(
              amount: amount.abs,
              payment_date: Time.current
            )
            success = true
            message = "Saldo inicial a favor actualizado exitosamente"
            flash[:notice] = message
          else
            message = "Error al actualizar el saldo inicial: #{existing_initial_balance.errors.full_messages.join(', ')}"
            flash[:alert] = message
            raise ActiveRecord::Rollback
          end
        else
          # Create a new payment for negative balance (customer has credit)
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
            success = true
            message = "Saldo inicial a favor creado exitosamente"
            flash[:notice] = message
          else
            message = "Error al crear el saldo inicial: #{payment.errors.full_messages.join(', ')}"
            flash[:alert] = message
            raise ActiveRecord::Rollback
          end
        end
      else
        message = "El monto debe ser diferente de cero"
        flash[:alert] = message
        raise ActiveRecord::Rollback
      end
    end

    respond_to do |format|
      format.html { redirect_to admin_account_receivables_path(user_id: @user.id), turbolinks: false }
      format.json do
        if success
          render json: { success: true, message: message }, status: :ok
        else
          render json: { success: false, error: message }, status: :unprocessable_entity
        end
      end
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
