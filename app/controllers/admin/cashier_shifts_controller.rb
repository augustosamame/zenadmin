class Admin::CashierShiftsController < Admin::AdminController
  requires_location_selection :new
  before_action :set_cashier_shift, only: [ :show, :edit, :update, :close, :modify_initial_balance ]

  def index
    # Base query with includes for eager loading
    base_query = CashierShift.includes([ :opened_by, :closed_by, :cashier, :location, { cashier: :location }, :cashier_transactions ])

    # Filter by location if applicable
    location_filtered = if @current_location
      base_query.where(cashier: { location_id: @current_location.id })
    else
      base_query
    end

    # Only admin users can see bank-type cashier shifts
    @cashier_shifts = if current_user.any_admin?
      # Admin users can see all cashier shifts
      location_filtered.order(id: :desc)
    else
      # Non-admin users can only see non-bank cashier shifts
      location_filtered.joins(:cashier).where.not(cashier: { cashier_type: :bank }).order(id: :desc)
    end

    @first_shift = @cashier_shifts.first
    @header_title = @first_shift ? "Turnos de Caja - #{@first_shift.cashier.location.name}" : "Turnos de Caja"
    @datatable_options = "resource_name:'CashierShift';"
  end

  def new
    @cashier_shift = CashierShift.new
    @available_cashiers = Cashier.where(location_id: @current_location.id)
    @cashier_shift.opened_at = Time.current
  end

  def create
    @cashier_shift = CashierShift.new(cashier_shift_params)
    @cashier_shift.opened_by = current_user
    @cashier_shift.total_sales_cents = 0
    @cashier_shift.date = Date.current
    if @cashier_shift.save
      if @cashier_shift.open?
        result = Services::Sales::CashierTransactionService.new(@cashier_shift).open_shift(current_user)
        if result[:success]
          redirect_to admin_cashier_shifts_path, notice: "Turno de caja abierto exitosamente."
        else
          redirect_to admin_cashier_shifts_path, alert: result[:error]
        end
      else
        redirect_to admin_cashier_shifts_path, notice: "Turno de caja abierto exitosamente."
      end
    else
      flash.now[:alert] = "Error al abrir el turno de caja."
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # Only admin users can see bank-type cashier shifts
    if !current_user.any_admin? && @cashier_shift.cashier.cashier_type == "bank"
      redirect_to admin_cashier_shifts_path, alert: "No tienes permisos para ver turnos de caja de tipo banco."
      return
    end

    # Paginate transactions with proper eager loading
    @transactions = @cashier_shift.cashier_transactions
                                  .includes(:payment_method, transactable: { payable: {} })
                                  .order(created_at: :desc)
                                  .page(params[:page])
                                  .per(50)

    # Pre-calculate payment method balances
    @payment_method_balances = calculate_payment_method_balances(@cashier_shift)

    # Only calculate sales by seller if the feature flag is enabled
    if $global_settings[:feature_flag_sales_attributed_to_seller]
      # Pre-load sellers data
      @sellers = User.where(id: @cashier_shift.sales_by_seller.keys).index_by(&:id)

      # Pre-calculate sales by seller
      @sales_by_seller = @cashier_shift.sales_by_seller

      # Pre-calculate document type sales totals
      @document_type_totals = {
        ruc: @cashier_shift.total_ruc_sales,
        rus: @cashier_shift.total_rus_sales
      }
    else
      # Set empty values when feature is disabled to avoid calculations
      @sellers = {}
      @sales_by_seller = {}
      @document_type_totals = {
        ruc: Money.new(0, "PEN"),
        rus: Money.new(0, "PEN")
      }
    end
  end

  def edit
  end

  def update
    if @cashier_shift.update(cashier_shift_params)
      redirect_to admin_cashier_shift_path(@cashier_shift), notice: "Turno de caja actualizado exitosamente."
    else
      flash.now[:alert] = "Error al actualizar el turno de caja."
      render :edit, status: :unprocessable_entity
    end
  end

  def close
    if @cashier_shift.open?
      result = Services::Sales::CashierTransactionService.new(@cashier_shift).close_shift(current_user)
      if result[:success]
        redirect_to admin_cashier_shift_path(@cashier_shift), notice: "Turno de caja cerrado exitosamente."
      else
        redirect_to admin_cashier_shift_path(@cashier_shift), alert: result[:error]
      end
    else
      redirect_to admin_cashier_shift_path(@cashier_shift), alert: "Este turno de caja ya está cerrado."
    end
  end

  def modify_initial_balance
    # Only allow admins to modify the initial balance
    unless current_user.any_admin?
      redirect_to admin_cashier_shift_path(@cashier_shift), alert: "No tienes permisos para modificar el saldo inicial."
      return
    end

    # Only allow modifying the initial balance of open shifts
    unless @cashier_shift.open?
      redirect_to admin_cashier_shift_path(@cashier_shift), alert: "No se puede modificar el saldo inicial de un turno cerrado."
      return
    end

    # Get the payment method (default to cash if not found)
    payment_method = PaymentMethod.find_by(name: "cash")

    # Convert the amount parameter to cents
    new_amount_cents = (params[:amount].to_f * 100).to_i

    # Get the current cash balance of the cashier shift
    current_balance = @cashier_shift.total_balance.cents

    # Calculate the difference between the new amount and the current balance
    difference_cents = new_amount_cents - current_balance

    ActiveRecord::Base.transaction do
      if difference_cents < 0
        # If the new amount is less than the current balance, create a cash outflow
        cash_outflow = CashOutflow.create!(
          cashier_shift: @cashier_shift,
          amount_cents: difference_cents.abs,
          paid_to: current_user,
          description: "Ajuste de saldo (#{params[:description]})"
        )

        # Create a cashier transaction for the outflow
        CashierTransaction.create!(
          cashier_shift: @cashier_shift,
          transactable: cash_outflow,
          amount_cents: difference_cents.abs,
          payment_method: payment_method
        )
      elsif difference_cents > 0
        # If the new amount is higher than the current balance, create a cash inflow
        cash_inflow = CashInflow.create!(
          cashier_shift: @cashier_shift,
          amount_cents: difference_cents,
          received_by: current_user,
          description: "Ajuste de saldo inicial (#{params[:description]})"
        )

        # Create a cashier transaction for the inflow
        CashierTransaction.create!(
          cashier_shift: @cashier_shift,
          transactable: cash_inflow,
          amount_cents: difference_cents,
          payment_method: payment_method
        )
      else
        # If the amount is the same, just add a note in the log
        Rails.logger.info("No change in balance amount for cashier shift ##{@cashier_shift.id}")
      end

      redirect_to admin_cashier_shift_path(@cashier_shift), notice: "Saldo inicial modificado exitosamente."
    rescue => e
      Rails.logger.error("Failed to modify initial balance: #{e.message}")
      redirect_to admin_cashier_shift_path(@cashier_shift), alert: "Error al modificar el saldo inicial: #{e.message}"
    end
  end

  private

  def set_cashier_shift
    @cashier_shift = CashierShift.find(params[:id])
    @current_cashier = @cashier_shift.cashier
    @current_cashier_shift = @cashier_shift
  end

  def cashier_shift_params
    params.require(:cashier_shift).permit(:cashier_id, :opened_at, :closed_at, :total_sales_cents, :opened_by, :closed_by, :status)
  end

  def calculate_payment_method_balances(cashier_shift)
    # Fetch all transactions with payment methods in a single query
    all_transactions = cashier_shift.cashier_transactions.includes(:payment_method).to_a
    transactions_by_method = all_transactions.group_by(&:payment_method)

    balances = []

    transactions_by_method.each do |payment_method, transactions|
      # Use amount_for_balance to correctly account for transaction types
      total_cents = transactions.sum(&:amount_for_balance)
      total = Money.new(total_cents, "PEN")

      cash_description = "Saldo Efectivo Anterior"

      # Add regular balance
      balances << {
        description: payment_method&.name == "cash" ? cash_description : (payment_method&.description || "Sin método"),
        amount: total
      }

      # For cash payments, add daily balance excluding previous shift
      if payment_method&.name == "cash"
        daily_cash = total - Money.new(cashier_shift.cash_from_previous_shift_cents, "PEN")
        balances << {
          description: "#{payment_method.description} del Día",
          amount: daily_cash
        }
      end
    end

    balances
  end
end
