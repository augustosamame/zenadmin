class Admin::AccountReceivablePaymentsController < Admin::AdminController
  before_action :set_account_receivable_payment, only: [ :edit, :update, :destroy ]

  def new
    if params[:account_receivable_id].present?
      # Redirect to payments/new with account_receivable_id
      redirect_to new_admin_payment_path(account_receivable_id: params[:account_receivable_id], from_account_receivable: true)
    elsif params[:payment_id].present?
      @payment = Payment.find(params[:payment_id])
      @account_receivables = AccountReceivable.where(user_id: @payment.user_id)
      render :index
    end
  end

  def create
    @payment = Payment.find(params[:payment_id])
    @account_receivable = AccountReceivable.find(params[:account_receivable_id])

    # Check if payment and account receivable belong to the same user
    unless @payment.user_id == @account_receivable.user_id
      flash[:alert] = "El pago y la cuenta por cobrar deben pertenecer al mismo cliente"
      redirect_to admin_account_receivables_path(user_id: @payment.user_id)
      return
    end

    # Check if payment is already applied to an account receivable
    if @payment.account_receivable.present?
      flash[:alert] = "Este pago ya ha sido aplicado a una cuenta por cobrar"
      redirect_to admin_account_receivables_path(user_id: @payment.user_id)
      return
    end

    # Calculate the amount to apply
    payment_amount = @payment.amount_cents
    receivable_remaining = @account_receivable.remaining_balance * 100
    amount_to_apply = [ payment_amount, receivable_remaining ].min

    ActiveRecord::Base.transaction do
      if amount_to_apply < payment_amount
        # Need to split the payment
        remainder = payment_amount - amount_to_apply

        # Update the original payment amount
        @payment.update!(amount_cents: amount_to_apply)

        # Create a new payment for the remainder
        new_payment = Payment.create!(
          payment_method_id: @payment.payment_method_id,
          user_id: @payment.user_id,
          region_id: @payment.region_id,
          payable_type: @payment.payable_type,
          payable_id: @payment.payable_id,
          cashier_shift_id: @payment.cashier_shift_id,
          amount_cents: remainder,
          currency: @payment.currency,
          payment_date: @payment.payment_date,
          status: @payment.status,
          description: "#{@payment.description} (saldo)",
          comment: @payment.comment,
          original_payment_id: @payment.id
        )
      end

      # Link the payment to the account receivable
      @payment.update!(account_receivable: @account_receivable)

      # Create the account receivable payment
      account_receivable_payment = AccountReceivablePayment.new(
        account_receivable_id: @account_receivable.id,
        payment_id: @payment.id,
        amount_cents: amount_to_apply,
        currency: @payment.currency,
        notes: params[:notes]
      )

      if account_receivable_payment.save
        flash[:notice] = "Pago aplicado exitosamente a la cuenta por cobrar"
        redirect_to success_admin_account_receivable_payments_path(user_id: @payment.user_id)
      else
        flash[:alert] = "Error al aplicar el pago: #{account_receivable_payment.errors.full_messages.join(', ')}"
        raise ActiveRecord::Rollback
      end
    end
  rescue => e
    flash[:alert] = "Error al procesar el pago: #{e.message}"
    redirect_to error_admin_account_receivable_payments_path(user_id: @payment.user_id)
  end

  def edit
    @account_receivable = @account_receivable_payment.account_receivable
  end

  def update
    if @account_receivable_payment.update(account_receivable_payment_params)
      flash[:notice] = "Pago actualizado exitosamente"
      redirect_to admin_account_receivable_path(@account_receivable_payment.account_receivable)
    else
      flash[:alert] = "Error al actualizar el pago: #{@account_receivable_payment.errors.full_messages.join(', ')}"
      render :edit
    end
  end

  def destroy
    account_receivable = @account_receivable_payment.account_receivable
    payment = @account_receivable_payment.payment

    ActiveRecord::Base.transaction do
      # Unlink the payment from the account receivable
      payment.update!(account_receivable_id: nil)

      # Delete the account receivable payment
      @account_receivable_payment.destroy!

      flash[:notice] = "Pago eliminado exitosamente"
    end

    redirect_to admin_account_receivable_path(account_receivable)
  rescue => e
    flash[:alert] = "Error al eliminar el pago: #{e.message}"
    redirect_to admin_account_receivable_path(account_receivable)
  end

  def success
    @user = User.find(params[:user_id])
    redirect_to admin_account_receivables_path(user_id: @user.id)
  end

  def error
    @user = User.find(params[:user_id])
    redirect_to admin_account_receivables_path(user_id: @user.id)
  end

  private

  def set_account_receivable_payment
    @account_receivable_payment = AccountReceivablePayment.find(params[:id])
  end

  def account_receivable_payment_params
    params.require(:account_receivable_payment).permit(:notes)
  end
end
