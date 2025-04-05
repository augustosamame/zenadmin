class Admin::AccountReceivablePaymentsController < Admin::AdminController
  before_action :set_account_receivable_payment, only: [ :edit, :update, :destroy ]

  def new
    if params[:account_receivable_id].present?
      # Redirect to payments/new with account_receivable_id
      redirect_to new_admin_payment_path(account_receivable_id: params[:account_receivable_id], from_account_receivable: true)
    elsif params[:payment_id].present?
      @payment = Payment.find(params[:payment_id])
      # Only show unpaid or partially paid account receivables
      @account_receivables = AccountReceivable.where(user_id: @payment.user_id)
                                             .where.not(status: :paid)
      render :new
    end
  end

  def create
    @payment = Payment.find(params[:payment_id])
    @account_receivable = AccountReceivable.find(params[:account_receivable_id])

    Rails.logger.info("PAYMENT DEBUG: Initial payment state - ID: #{@payment.id}, amount: #{@payment.amount_cents}, account_receivable_id: #{@payment.account_receivable_id}")
    Rails.logger.info("AR DEBUG: Initial account receivable state - ID: #{@account_receivable.id}, amount: #{@account_receivable.amount_cents}, status: #{@account_receivable.status}")

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
    
    # Get the remaining balance (could be 0 if already paid)
    receivable_remaining = @account_receivable.remaining_balance * 100
    
    # Use params amount if provided, otherwise use payment amount for paid receivables 
    # or calculate from remaining balance for unpaid ones
    amount_to_apply = if params[:amount_cents].present? && params[:amount_cents].to_i > 0
                        # Use the explicitly provided amount
                        [params[:amount_cents].to_i, payment_amount].min
                      elsif @account_receivable.paid? && receivable_remaining <= 0
                        # For paid receivables with no remaining balance, use the full payment amount
                        payment_amount
                      else
                        # For unpaid receivables, use the minimum of payment amount and remaining balance
                        [payment_amount, receivable_remaining].min
                      end
    
    # Ensure we're not applying a zero amount
    if amount_to_apply <= 0
      flash[:alert] = "No se puede aplicar un monto de cero o negativo"
      redirect_to new_admin_account_receivable_payment_path(payment_id: @payment.id)
      return
    end
    
    Rails.logger.info("PAYMENT DEBUG: Amount calculation - payment_amount: #{payment_amount}, receivable_remaining: #{receivable_remaining}, amount_to_apply: #{amount_to_apply}, receivable_status: #{@account_receivable.status}")

    success = false
    error_message = nil

    ActiveRecord::Base.transaction do
      if amount_to_apply < payment_amount
        # Need to split the payment
        remainder = payment_amount - amount_to_apply

        Rails.logger.info("PAYMENT DEBUG: Splitting payment - original amount: #{payment_amount}, applied amount: #{amount_to_apply}, remainder: #{remainder}")

        # Update the original payment amount
        @payment.update!(amount_cents: amount_to_apply)
        Rails.logger.info("PAYMENT DEBUG: After update - ID: #{@payment.id}, new amount: #{@payment.amount_cents}, account_receivable_id: #{@payment.account_receivable_id}")

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
        Rails.logger.info("PAYMENT DEBUG: Created new remainder payment - ID: #{new_payment.id}, amount: #{new_payment.amount_cents}")
      end

      # Link the payment to the account receivable
      result = @payment.update!(
        account_receivable: @account_receivable,
        payable_type: "Order",
        payable_id: @account_receivable.order_id
      )
      Rails.logger.info("PAYMENT DEBUG: Linking payment to AR - success: #{result}, payment.account_receivable_id: #{@payment.reload.account_receivable_id}")

      # Create the account receivable payment
      account_receivable_payment = AccountReceivablePayment.new(
        account_receivable_id: @account_receivable.id,
        payment_id: @payment.id,
        amount_cents: amount_to_apply,
        currency: @payment.currency,
        notes: params[:notes]
      )
      
      Rails.logger.info("AR PAYMENT DEBUG: New AR payment - account_receivable_id: #{account_receivable_payment.account_receivable_id}, payment_id: #{account_receivable_payment.payment_id}, amount: #{account_receivable_payment.amount_cents}")

      if account_receivable_payment.save
        Rails.logger.info("AR PAYMENT DEBUG: AR payment saved successfully - ID: #{account_receivable_payment.id}")
        
        # Update the account receivable status based on the remaining balance
        total_payments = @account_receivable.account_receivable_payments.sum(:amount_cents)
        Rails.logger.info("AR DEBUG: Total payments calculated: #{total_payments}, AR amount: #{@account_receivable.amount_cents}")
        
        if total_payments >= @account_receivable.amount_cents
          result = @account_receivable.update!(status: :paid)
          Rails.logger.info("AR DEBUG: Updated AR status to paid - success: #{result}, new status: #{@account_receivable.reload.status}")
        elsif total_payments > 0
          result = @account_receivable.update!(status: :partially_paid)
          Rails.logger.info("AR DEBUG: Updated AR status to partially_paid - success: #{result}, new status: #{@account_receivable.reload.status}")
        end
        
        # Force reload to check if updates were persisted
        @payment.reload
        @account_receivable.reload
        
        Rails.logger.info("FINAL STATE: Payment - ID: #{@payment.id}, account_receivable_id: #{@payment.account_receivable_id}")
        Rails.logger.info("FINAL STATE: Account Receivable - ID: #{@account_receivable.id}, status: #{@account_receivable.status}")
        
        success = true
      else
        error_message = account_receivable_payment.errors.full_messages.join(', ')
        Rails.logger.error("AR PAYMENT DEBUG: Failed to save AR payment - errors: #{error_message}")
        raise ActiveRecord::Rollback
      end
    end

    # Redirect based on the success flag (outside the transaction)
    if success
      flash[:notice] = "Pago aplicado exitosamente a la cuenta por cobrar"
      redirect_to success_admin_account_receivable_payments_path(user_id: @payment.user_id)
    else
      flash[:alert] = "Error al aplicar el pago: #{error_message || 'Error desconocido'}"
      redirect_to error_admin_account_receivable_payments_path(user_id: @payment.user_id)
    end
  rescue => e
    Rails.logger.error("PAYMENT ERROR: #{e.message}\n#{e.backtrace.join("\n")}")
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
