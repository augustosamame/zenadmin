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
    @payment = Payment.new
    generic_customer = User.find_by(email: "generic_customer@devtechperu.com")
    @customer_users = User.with_role("customer") - [ generic_customer ]
  end

  def create
    @payment = Payment.new(payment_params)
    @payment.status = "paid"
    if @payment.save!
      redirect_to admin_payments_path
    else
      render :new, status: :unprocessable_entity
    end
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
      :due_date
    )
  end

  def datatable_json
    payments = Payment.includes(:user, :payment_method, :location, :cashier, :cashier_shift)
                     .joins(:payment_method)

    # Location filter
    if @current_location && !current_user.any_admin_or_supervisor?
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
