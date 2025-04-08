class Admin::PaymentsController < Admin::AdminController
  include MoneyRails::ActionViewExtension
  include CurrencyFormattable
  include AdminHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Context
  include ActionView::Helpers::OutputSafetyHelper
  include ActionView::Helpers::CaptureHelper

  def index
    respond_to do |format|
      format.html do
        @payments = if @current_location
          Payment.includes([ :payment_method, :location, :cashier, :cashier_shift, payable: :user ])
                .joins(cashier_shift: { cashier: :location })
                .where(cashiers: { location_id: @current_location.id })
                .order(id: :desc)
                .limit(10)
        else
          Payment.includes([ :payment_method, :location, :cashier, :cashier_shift, payable: :user ])
                .order(id: :desc)
                .limit(10)
        end

        create_button = $global_settings[:pos_can_create_unpaid_orders]
        @datatable_options = "server_side:true;resource_name:'Payment';create_button:#{create_button};sort_1_desc;"
      end

      format.json do
        render json: datatable_json
      end
    end
  end

  def show
    @payment = Payment.includes(:payment_method, :payable).find(params[:id])
  end

  def new
    # shown an error if @current_cashier_shift is not present
    if @current_cashier_shift.blank?
      flash[:error] = "No hay un turno de caja abierto. Por favor, abre un turno de caja antes de crear un pago."
      redirect_to admin_cashier_shifts_path
      return
    end

    @payment = Payment.new
    generic_customer = User.find_by(email: "generic_customer@devtechperu.com")
    @customer_users = User.with_role("customer") - [ generic_customer ]

    # Load open cashier shifts for admins and supervisors
    @open_cashier_shifts = CashierShift.includes(:cashier).where(status: :open).order("cashiers.name")

    # Pre-select user if user_id is provided
    if params[:user_id].present?
      @payment.user_id = params[:user_id]
    end

    # Handle account_receivable_id
    if params[:account_receivable_id].present?
      # Store in session only if explicitly coming from account receivable
      session[:account_receivable_id] = params[:account_receivable_id]
      @account_receivable = AccountReceivable.find(params[:account_receivable_id])

      if @account_receivable.present?
        # Pre-select the user from the account receivable
        @payment.user_id = @account_receivable.user_id
        # Pre-populate the amount with the remaining balance
        @payment.amount = @account_receivable.remaining_balance
      end
    elsif params[:from_account_receivable].blank?
      # Clear the session if not explicitly coming from account receivable
      session.delete(:account_receivable_id)
    elsif session[:account_receivable_id].present?
      # Only load the account receivable if we're coming from account receivable
      @account_receivable = AccountReceivable.find(session[:account_receivable_id])

      if @account_receivable.present?
        # Pre-select the user from the account receivable
        @payment.user_id = @account_receivable.user_id
        # Pre-populate the amount with the remaining balance
        @payment.amount = @account_receivable.remaining_balance
      end
    end
  end

  def create
    @payment = Payment.new(payment_params)
    @payment.status = "paid"

    @open_cashier_shifts = CashierShift.includes(:cashier).where(status: :open).order("cashiers.name")

    @payment.cashier_shift ||= @current_cashier_shift

    ActiveRecord::Base.transaction do
      if @payment.save
        # If there's an account_receivable_id in the session, apply the payment to it
        if session[:account_receivable_id].present?
          account_receivable_id = session[:account_receivable_id]
          account_receivable = AccountReceivable.find(account_receivable_id)
          old_credit_payment_id = account_receivable.payment_id

          # Apply the payment to the account receivable
          # Calculate the amount to apply
          payment_amount = @payment.amount_cents
          receivable_remaining = account_receivable.remaining_balance * 100
          amount_to_apply = [ payment_amount, receivable_remaining ].min

          if amount_to_apply < payment_amount
            # Need to split the payment
            # Update the original payment amount
            @payment.update!(amount_cents: amount_to_apply)

            # Create a new payment without cashier transaction for the remainder
            new_payment = Payment.create!(
              payment_method_id: @payment.payment_method_id,
              user_id: @payment.user_id,
              cashier_shift_id: @payment.cashier_shift_id,
              amount_cents: payment_amount - amount_to_apply,
              currency: @payment.currency,
              payment_date: @payment.payment_date,
              status: @payment.status,
              comment: "#{@payment.comment} (Saldo restante)",
              original_payment_id: @payment.id
            )
          end

          # Link the payment to the account receivable
          @payment.update!(account_receivable: account_receivable)

          # Create the account receivable payment
          account_receivable_payment = AccountReceivablePayment.create!(
            account_receivable_id: account_receivable.id,
            payment_id: @payment.id,
            amount_cents: @payment.amount_cents,
            currency: @payment.currency,
            notes: @payment.comment
          )

          # update old_credit_payment_to_reduce_saldo

          old_credit_payment = Payment.find(old_credit_payment_id)
          old_credit_payment.update_columns(
            status: "paid",
            account_receivable_id: account_receivable.id
          )


          # Clear the session
          session.delete(:account_receivable_id)

          redirect_to admin_account_receivables_path(user_id: account_receivable.user_id), notice: "Pago creado y aplicado a la cuenta por cobrar exitosamente"
        else
          redirect_to admin_payments_path, notice: "Pago creado exitosamente"
        end
      else
        generic_customer = User.find_by(email: "generic_customer@devtechperu.com")
        @customer_users = User.with_role("customer") - [ generic_customer ]
        render :new, status: :unprocessable_entity
      end
    end
  rescue => e
    generic_customer = User.find_by(email: "generic_customer@devtechperu.com")
    @customer_users = User.with_role("customer") - [ generic_customer ]
    flash.now[:alert] = "Error al crear el pago: #{e.message}"
    render :new, status: :unprocessable_entity
  end

  private

  def payment_params
    params.require(:payment).permit(
      :payment_method_id,
      :user_id,
      :payable_id,
      :payable_type,
      :amount,
      :currency,
      :payment_date,
      :comment,
      :status,
      :processor_transacion_id,
      :due_date,
      :cashier_shift_id
    )
  end

  def datatable_json
    payments = Payment.includes(:user, :payment_method, :location, :cashier, :cashier_shift)
                     .joins(:payment_method)

    # Location filter
    if @current_location && current_user.any_admin_or_supervisor?
      payments = payments.joins(cashier_shift: { cashier: :location })
                        .where(cashiers: { location_id: @current_location.id })
    end

    # Apply search filter
    if params[:search][:value].present?
      payments = payments.search_by_all_fields(params[:search][:value])
    end

    # Apply sorting
    if params[:order].present?
      column_index = params[:order]["0"][:column].to_i
      direction = params[:order]["0"][:dir]

      order_clause = case column_index
      when 0
        current_user.any_admin_or_supervisor? ? [ "locations.name", direction ] : nil
      when 1
        [ "payments.custom_id", direction ]
      when 2
        [ "payments.payment_date", direction ]
      when 3
        payments = payments.joins(:user)
        [ [ "users.first_name", "users.last_name" ], direction ]
      when 4
        [ "payment_methods.description", direction ]
      when 5
        [ "payments.amount_cents", direction ]
      when 6
        [ "payments.processor_transacion_id", direction ]
      when 7
        [ "payments.status", direction ]
      when 8
        [ "payments.payable_type", direction ]
      when 9
        [ "payments.id", direction ]
      else
        [ "payments.id", "DESC" ]
      end

      if order_clause.present?
        if order_clause[0].is_a?(Array)
          # Handle multiple columns
          order_sql = order_clause[0].map { |col| "#{col} #{order_clause[1]}" }.join(", ")
          payments = payments.reorder(Arel.sql(order_sql))
        else
          payments = payments.reorder(Arel.sql("#{order_clause[0]} #{order_clause[1]}"))
        end
      end
    else
      payments = payments.order(id: :desc) # Default sorting
    end

    # Pagination
    paginated_payments = payments.page(params[:start].to_i / params[:length].to_i + 1)
                                .per(params[:length].to_i)

    {
      draw: params[:draw].to_i,
      recordsTotal: Payment.count,
      recordsFiltered: payments.count,
      data: paginated_payments.map do |payment|
        row = []

        if current_user.any_admin_or_supervisor?
          row << payment&.location&.name
        end

        row.concat([
          payment.custom_id,
          friendly_date(current_user, payment.payment_date),
          payment.payable ? payment&.payable&.user&.name : payment&.user&.name,
          payment.payment_method.description,
          format_currency(payment.amount),
          payment.processor_transacion_id,
          payment.translated_status,
          translated_payable_type(payment.payable_type),
          payment.payable&.custom_id
        ])

        row
      end
    }
  end
end
