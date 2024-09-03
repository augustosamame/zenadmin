class Admin::CashierShiftsController < Admin::AdminController
  before_action :set_cashier_shift, only: [ :show, :edit, :update, :close ]

  def index
    @cashier_shifts = CashierShift.includes([ :opened_by, :closed_by, :cashier ]).where(cashier_id: @current_cashier.id).order(id: :desc)
    @first_shift = @cashier_shifts.first
    @header_title = @first_shift ? "Turnos de Caja - #{@first_shift.cashier.location.name} - #{@first_shift.cashier.name}" : "Turnos de Caja"
    @datatable_options = "resource_name:'CashierShift';"
  end

  def new
    @cashier_shift = CashierShift.new
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
    @transactions = @cashier_shift.cashier_transactions.order(created_at: :desc)
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

  private

  def set_cashier_shift
    @cashier_shift = CashierShift.find(params[:id])
  end

  def cashier_shift_params
    params.require(:cashier_shift).permit(:cashier_id, :opened_at, :closed_at, :total_sales_cents, :opened_by, :closed_by, :status)
  end
end
