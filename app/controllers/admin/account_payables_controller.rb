class Admin::AccountPayablesController < Admin::AdminController
  before_action :set_account_payable, only: %i[show]

  def vendors_index
    authorize! :read, Purchases::Vendor
    
    respond_to do |format|
      format.html do
        @vendors = Purchases::Vendor.all

        # Precompute balances for all vendors to avoid N+1 queries
        @vendor_balances = {}

        # Get all vendor IDs
        vendor_ids = @vendors.pluck(:id)

        # Get all purchase invoices in one query
        payables_by_vendor = PurchaseInvoice.where(vendor_id: vendor_ids)
                                           .group(:vendor_id)
                                           .sum(:amount_cents)

        # Get all applied payments in one query
        applied_payments_by_vendor = {}

        # This query gets all payments applied to purchase invoices for each vendor
        applied_payments_query = PurchaseInvoicePayment.joins(:purchase_invoice)
                                                      .where(purchase_invoices: { vendor_id: vendor_ids })
                                                      .group("purchase_invoices.vendor_id")
                                                      .sum(:amount_cents)

        applied_payments_query.each do |vendor_id, amount|
          applied_payments_by_vendor[vendor_id] = amount
        end

        # Get all unapplied payments in one query
        unapplied_payments_by_vendor = PurchasePayment.unapplied
                                                     .joins(:payable)
                                                     .where(payable_type: "Purchases::Purchase")
                                                     .joins("INNER JOIN purchases_purchases ON purchases_purchases.id = purchase_payments.payable_id")
                                                     .where(purchases_purchases: { vendor_id: vendor_ids })
                                                     .group("purchases_purchases.vendor_id")
                                                     .sum(:amount_cents)

        @vendors.each do |vendor|
          total_payables = payables_by_vendor[vendor.id] || 0
          total_applied_payments = applied_payments_by_vendor[vendor.id] || 0
          total_unapplied_payments = unapplied_payments_by_vendor[vendor.id] || 0
          total_payments = total_applied_payments + total_unapplied_payments

          # Calculate balance (payables - payments)
          @vendor_balances[vendor.id] = (total_payables - total_payments) / 100.0
        end

        @datatable_options = "resource_name:'Vendor';sort_0_desc;create_button:false;balance_sort_5;"
      end
    end
  end

  def index
    authorize! :read, PurchaseInvoice
    if params[:vendor_id].present?
      @vendor = Purchases::Vendor.find(params[:vendor_id])
      @purchase_invoices = PurchaseInvoice.where(vendor_id: params[:vendor_id])
      @unapplied_payments = PurchasePayment.unapplied
                                          .joins(:payable)
                                          .where(payable_type: "Purchases::Purchase")
                                          .joins("INNER JOIN purchases_purchases ON purchases_purchases.id = purchase_payments.payable_id")
                                          .where(purchases_purchases: { vendor_id: params[:vendor_id] })
                                          .order(id: :desc)
      
      @applied_payments = PurchaseInvoicePayment.joins(:purchase_invoice)
                                               .where(purchase_invoices: { vendor_id: params[:vendor_id] })
                                               .includes(:purchase_payment)
      
      @total_purchases = Purchases::Purchase.where(vendor_id: params[:vendor_id]).sum(:total_price_cents) / 100.0
      @total_credit_purchases = @purchase_invoices.sum(:amount_cents) / 100.0
      @total_paid = (@applied_payments.sum(:amount_cents) / 100.0) + (@unapplied_payments.sum(:amount_cents) / 100.0)
      @total_unapplied_payments = @unapplied_payments.sum(:amount_cents) / 100.0
      @total_pending_previous_period = @vendor.account_payable_initial_balance.to_f
      @total_pending = @purchase_invoices.sum(:amount_cents) / 100.0 - @total_paid

      # Check if vendor has any purchase invoices or payments
      @has_transactions = @purchase_invoices.any? || @unapplied_payments.any? || @applied_payments.any?
    else
      raise "Vendor ID is required"
    end
  end

  def show
    @purchase_invoice = PurchaseInvoice.find(params[:id])
  end

  def payments_calendar
    authorize! :read, PurchaseInvoice
    
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.today.beginning_of_month
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today.end_of_month
    
    # Get all purchase invoices with due dates in the specified range
    @purchase_invoices = PurchaseInvoice.includes(:vendor)
                                       .where("planned_payment_date BETWEEN ? AND ?", @start_date, @end_date)
                                       .where.not(payment_status: :paid)
                                       .order(:planned_payment_date)
    
    # Group purchase invoices by due date
    @grouped_invoices = @purchase_invoices.group_by { |invoice| invoice.planned_payment_date&.to_date }
    
    # Calculate total amount due for each day
    @daily_totals = {}
    @grouped_invoices.each do |date, invoices|
      @daily_totals[date] = invoices.sum { |invoice| invoice.amount_cents - invoice.purchase_invoice_payments.sum(:amount_cents) } / 100.0
    end
    
    # Calculate overall total
    @total_due = @purchase_invoices.sum { |invoice| invoice.amount_cents - invoice.purchase_invoice_payments.sum(:amount_cents) } / 100.0
  end

  def create_initial_balance
    authorize! :manage, PurchaseInvoice
    
    @vendor = Purchases::Vendor.find(params[:vendor_id])
    
    # Convert amount to cents
    amount = params[:amount].to_f
    
    success = false
    message = ""
    
    ActiveRecord::Base.transaction do
      if amount > 0
        # Find existing initial balance or create a new one
        existing_initial_balance = PurchaseInvoice.find_by(vendor: @vendor, description: "Saldo inicial")
        
        if existing_initial_balance.present?
          # Update the existing purchase invoice
          if existing_initial_balance.update(
              amount: amount,
              planned_payment_date: params[:due_date].present? ? Time.zone.parse(params[:due_date]).change(hour: 12) : nil
            )
            success = true
            message = "Saldo inicial por pagar actualizado exitosamente"
            flash[:notice] = message
          else
            message = "Error al actualizar el saldo inicial: #{existing_initial_balance.errors.full_messages.join(', ')}"
            flash[:alert] = message
            raise ActiveRecord::Rollback
          end
        else
          # Create a new purchase invoice for positive balance (company owes money)
          purchase_invoice = PurchaseInvoice.new(
            vendor: @vendor,
            amount: amount,
            currency: "PEN",
            payment_status: :pending,
            purchase_invoice_type: :factura,
            purchase_invoice_date: Date.today,
            description: "Saldo inicial",
            planned_payment_date: params[:due_date].present? ? Time.zone.parse(params[:due_date]).change(hour: 12) : nil
          )

          if purchase_invoice.save
            success = true
            message = "Saldo inicial por pagar creado exitosamente"
            flash[:notice] = message
          else
            message = "Error al crear el saldo inicial: #{purchase_invoice.errors.full_messages.join(', ')}"
            flash[:alert] = message
            raise ActiveRecord::Rollback
          end
        end
      elsif amount < 0
        # Find existing initial balance payment or create a new one
        existing_initial_balance = PurchasePayment.find_by(description: "Saldo inicial a favor", 
                                                          payable_type: "Purchases::Vendor", 
                                                          payable_id: @vendor.id)

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
          # Create a new payment for negative balance (company has credit with vendor)
          payment = PurchasePayment.new(
            user: current_user,
            amount: amount.abs,
            currency: "PEN",
            status: :paid,
            payment_method: PaymentMethod.find_by(name: "cash") || PaymentMethod.first,
            payment_date: Time.current,
            payable_type: "Purchases::Vendor",
            payable_id: @vendor.id,
            description: "Saldo inicial a favor",
            comment: "Saldo inicial a favor con el proveedor"
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
      format.html { redirect_to admin_account_payables_path(vendor_id: @vendor.id), turbolinks: false }
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

    def set_account_payable
      @purchase_invoice = PurchaseInvoice.find(params[:id])
    end

    def payable_status_class(status)
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
