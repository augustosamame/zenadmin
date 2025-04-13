class Admin::AccountPayablePaymentsController < Admin::AdminController
  before_action :set_account_payable_payment, only: [ :edit, :update, :destroy ]

  def new
    if params[:purchase_invoice_id].present?
      # Redirect to purchase_payments/new with purchase_invoice_id
      redirect_to new_admin_purchase_payment_path(purchase_invoice_id: params[:purchase_invoice_id], from_purchase_invoice: true)
    elsif params[:purchase_payment_id].present?
      @purchase_payment = PurchasePayment.find(params[:purchase_payment_id])
      
      # Determine vendor_id based on payment's associations
      vendor_id = if @purchase_payment.vendor_id.present?
                    @purchase_payment.vendor_id
                  elsif @purchase_payment.payable.present? && @purchase_payment.payable.respond_to?(:vendor_id)
                    @purchase_payment.payable.vendor_id
                  elsif @purchase_payment.payable_type == "Purchases::Vendor" && @purchase_payment.payable_id.present?
                    @purchase_payment.payable_id
                  else
                    nil
                  end
      
      if vendor_id.present?
        # Only show unpaid or partially paid purchase invoices
        @purchase_invoices = PurchaseInvoice.where(vendor_id: vendor_id)
                                           .where.not(payment_status: :paid)
        render :new
      else
        flash[:alert] = "No se pudo determinar el proveedor para este pago"
        redirect_to admin_account_payables_path
      end
    end
  end

  def create
    @purchase_payment = PurchasePayment.find(params[:purchase_payment_id])
    @purchase_invoice = PurchaseInvoice.find(params[:purchase_invoice_id])

    Rails.logger.info("PAYMENT DEBUG: Initial payment state - ID: #{@purchase_payment.id}, amount: #{@purchase_payment.amount_cents}, purchase_invoice_id: #{@purchase_payment.purchase_invoice_id}")
    Rails.logger.info("PI DEBUG: Initial purchase invoice state - ID: #{@purchase_invoice.id}, amount: #{@purchase_invoice.amount_cents}, status: #{@purchase_invoice.payment_status}")

    # Determine vendor_id based on payment's associations
    vendor_id_from_payment = if @purchase_payment.vendor_id.present?
                              @purchase_payment.vendor_id
                            elsif @purchase_payment.payable.present? && @purchase_payment.payable.respond_to?(:vendor_id)
                              @purchase_payment.payable.vendor_id
                            elsif @purchase_payment.payable_type == "Purchases::Vendor" && @purchase_payment.payable_id.present?
                              @purchase_payment.payable_id
                            else
                              nil
                            end

    unless vendor_id_from_payment == @purchase_invoice.vendor_id
      flash[:alert] = "El pago y la factura deben pertenecer al mismo proveedor"
      redirect_to admin_account_payables_path(vendor_id: @purchase_invoice.vendor_id)
      return
    end

    # Check if payment is already fully applied to purchase invoices
    total_applied = @purchase_payment.purchase_invoice_payments.sum(:amount_cents)
    if total_applied >= @purchase_payment.amount_cents
      flash[:alert] = "Este pago ya ha sido aplicado completamente"
      redirect_to admin_account_payables_path(vendor_id: @purchase_invoice.vendor_id)
      return
    end

    # Calculate the amount to apply
    payment_amount = @purchase_payment.amount_cents - total_applied
    
    # Get the remaining balance (could be 0 if already paid)
    invoice_remaining = @purchase_invoice.amount_cents - @purchase_invoice.purchase_invoice_payments.sum(:amount_cents)
    
    # Apply the full payment amount or the remaining invoice balance, whichever is smaller
    amount_to_apply = [payment_amount, invoice_remaining].min
    
    # Ensure we're not applying a zero amount
    if amount_to_apply <= 0
      flash[:alert] = "No se puede aplicar un monto de cero o negativo"
      redirect_to new_admin_account_payable_payment_path(purchase_payment_id: @purchase_payment.id)
      return
    end
    
    Rails.logger.info("PAYMENT DEBUG: Amount calculation - payment_amount: #{payment_amount}, invoice_remaining: #{invoice_remaining}, amount_to_apply: #{amount_to_apply}, invoice_status: #{@purchase_invoice.payment_status}")

    success = false
    error_message = nil

    ActiveRecord::Base.transaction do
      # Create the purchase invoice payment
      purchase_invoice_payment = PurchaseInvoicePayment.new(
        purchase_payment: @purchase_payment,
        purchase_invoice: @purchase_invoice,
        amount_cents: amount_to_apply,
        currency: @purchase_payment.currency,
        notes: params[:notes]
      )

      if purchase_invoice_payment.save
        Rails.logger.info("PI PAYMENT DEBUG: PI payment saved successfully - ID: #{purchase_invoice_payment.id}")
        
        # Update the purchase payment status if fully applied
        remaining_payment_amount = @purchase_payment.amount_cents - @purchase_payment.purchase_invoice_payments.sum(:amount_cents)
        if remaining_payment_amount <= 0
          @purchase_payment.update(status: :paid)
        elsif remaining_payment_amount < @purchase_payment.amount_cents
          @purchase_payment.update(status: :partially_paid)
        end
        
        # The purchase_invoice_payment after_create callback will update the purchase invoice status
        
        # Force reload to check if updates were persisted
        @purchase_payment.reload
        @purchase_invoice.reload
        
        Rails.logger.info("FINAL STATE: Payment - ID: #{@purchase_payment.id}")
        Rails.logger.info("FINAL STATE: Purchase Invoice - ID: #{@purchase_invoice.id}, status: #{@purchase_invoice.payment_status}")
        
        success = true
      else
        error_message = purchase_invoice_payment.errors.full_messages.join(', ')
        Rails.logger.error("PI PAYMENT DEBUG: Failed to save PI payment - errors: #{error_message}")
        raise ActiveRecord::Rollback
      end
    end

    # Redirect based on the success flag (outside the transaction)
    if success
      flash[:notice] = "Pago aplicado exitosamente a la factura"
      redirect_to success_admin_account_payable_payments_path(vendor_id: @purchase_invoice.vendor_id)
    else
      flash[:alert] = "Error al aplicar el pago: #{error_message || 'Error desconocido'}"
      redirect_to error_admin_account_payable_payments_path(vendor_id: @purchase_invoice.vendor_id)
    end
  rescue => e
    Rails.logger.error("PAYMENT ERROR: #{e.message}\n#{e.backtrace.join("\n")}")
    flash[:alert] = "Error al procesar el pago: #{e.message}"
    redirect_to error_admin_account_payable_payments_path(vendor_id: @purchase_invoice&.vendor_id || params[:vendor_id])
  end

  def edit
    @purchase_invoice = @account_payable_payment.purchase_invoice
  end

  def update
    if @account_payable_payment.update(account_payable_payment_params)
      flash[:notice] = "Pago actualizado exitosamente"
      redirect_to admin_purchase_invoice_path(@account_payable_payment.purchase_invoice)
    else
      flash[:alert] = "Error al actualizar el pago: #{@account_payable_payment.errors.full_messages.join(', ')}"
      render :edit
    end
  end

  def destroy
    purchase_invoice = @account_payable_payment.purchase_invoice
    purchase_payment = @account_payable_payment.purchase_payment

    ActiveRecord::Base.transaction do
      # Delete the purchase invoice payment
      @account_payable_payment.destroy!

      flash[:notice] = "Pago eliminado exitosamente"
    end

    redirect_to admin_purchase_invoice_path(purchase_invoice)
  rescue => e
    flash[:alert] = "Error al eliminar el pago: #{e.message}"
    redirect_to admin_purchase_invoice_path(purchase_invoice)
  end

  def success
    @vendor = Purchases::Vendor.find(params[:vendor_id])
    redirect_to admin_account_payables_path(vendor_id: @vendor.id)
  end

  def error
    @vendor = Purchases::Vendor.find(params[:vendor_id])
    redirect_to admin_account_payables_path(vendor_id: @vendor.id)
  end

  private

  def set_account_payable_payment
    @account_payable_payment = PurchaseInvoicePayment.find(params[:id])
  end

  def account_payable_payment_params
    params.permit(:notes)
  end
end
