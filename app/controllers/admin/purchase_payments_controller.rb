class Admin::PurchasePaymentsController < Admin::AdminController
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
        # Load payments with appropriate associations
        @purchase_payments = if @current_location && current_user.any_admin_or_supervisor?
          PurchasePayment.includes(:payable, cashier_shift: :cashier)
                .where(region_id: @current_location.region_id)
                .order(id: :desc)
                .limit(10)
        else
          PurchasePayment.includes(:payable, cashier_shift: :cashier)
                .order(id: :desc)
                .limit(10)
        end

        # Manually load payables to avoid namespace issues
        payable_ids_by_type = {}
        @purchase_payments.each do |payment|
          # Normalize the payable type
          if payment.payable_type == "Purchases::PurchaseInvoice"
            payment.payable_type = "PurchaseInvoice"
          end
          
          # Group payable IDs by type for efficient loading
          payable_ids_by_type[payment.payable_type] ||= []
          payable_ids_by_type[payment.payable_type] << payment.payable_id if payment.payable_id.present?
        end
        
        # Load payables by type
        payables_by_type_and_id = {}
        payable_ids_by_type.each do |type, ids|
          next if ids.empty?
          
          # Handle different payable types
          klass = case type
                  when "Purchases::Purchase"
                    Purchases::Purchase
                  when "Purchases::Vendor"
                    Purchases::Vendor
                  when "PurchaseInvoice"
                    PurchaseInvoice
                  else
                    next
                  end
          
          # Load records and index them by ID
          records = klass.where(id: ids.uniq).includes(:vendor) rescue klass.where(id: ids.uniq)
          records.each do |record|
            payables_by_type_and_id[type] ||= {}
            payables_by_type_and_id[type][record.id] = record
          end
        end
        
        # Assign payables to payments
        @purchase_payments.each do |payment|
          next unless payment.payable_id.present? && payment.payable_type.present?
          next unless payables_by_type_and_id[payment.payable_type]&.key?(payment.payable_id)
          
          # Use instance variable to store the payable
          payment.instance_variable_set(:@payable, payables_by_type_and_id[payment.payable_type][payment.payable_id])
        end

        @datatable_options = "server_side:true;resource_name:'PurchasePayment';create_button:true;sort_1_desc;"
      end

      format.json do
        render json: datatable_json
      end
    end
  end

  def show
    @purchase_payment = PurchasePayment.includes(:payment_method, :payable).find(params[:id])
  end

  def fetch_purchases
    vendor = Purchases::Vendor.find(params[:vendor_id])
    purchases = Purchases::Purchase.where(vendor_id: vendor.id)
    
    render json: { 
      purchases: purchases.map { |p| { id: p.id, custom_id: p.custom_id } }
    }
  end

  def new
    @purchase_payment = PurchasePayment.new
    @purchase_payment.payment_date = Time.current
    @vendors = Purchases::Vendor.all
    
    # Get cashiers for dropdown
    @cashiers = Cashier.where(status: :active).order(:name)
    @cashiers_with_open_shifts = Cashier.active_with_open_shift.order(:name)
    
    # The cashier_shift will be set in create based on the selected cashier
    
    
    @elligible_payment_methods = PaymentMethod.active.where(payment_method_type: "standard")
    
    # Pre-select vendor if vendor_id is provided
    if params[:vendor_id].present?
      @vendor = Purchases::Vendor.find(params[:vendor_id])
      @purchases = Purchases::Purchase.where(vendor_id: params[:vendor_id])
    end

    # Handle purchase_invoice_id
    if params[:purchase_invoice_id].present?
      # Store in session only if explicitly coming from purchase invoice
      session[:purchase_invoice_id] = params[:purchase_invoice_id]
      @purchase_invoice = PurchaseInvoice.find(params[:purchase_invoice_id])

      if @purchase_invoice.present?
        # Pre-select the vendor from the purchase invoice
        @vendor = @purchase_invoice.vendor
        @purchases = Purchases::Purchase.where(vendor_id: @vendor.id)
        # Pre-populate the amount with the remaining balance
        remaining_balance = @purchase_invoice.amount_cents - @purchase_invoice.purchase_invoice_payments.sum(:amount_cents)
        @purchase_payment.amount = remaining_balance / 100.0
      end
    elsif params[:from_purchase_invoice].blank?
      # Clear the session if not explicitly coming from purchase invoice
      session.delete(:purchase_invoice_id)
    elsif session[:purchase_invoice_id].present?
      # Only load the purchase invoice if we're coming from purchase invoice
      @purchase_invoice = PurchaseInvoice.find(session[:purchase_invoice_id])

      if @purchase_invoice.present?
        # Pre-select the vendor from the purchase invoice
        @vendor = @purchase_invoice.vendor
        @purchases = Purchases::Purchase.where(vendor_id: @vendor.id)
        # Pre-populate the amount with the remaining balance
        remaining_balance = @purchase_invoice.amount_cents - @purchase_invoice.purchase_invoice_payments.sum(:amount_cents)
        @purchase_payment.amount = remaining_balance / 100.0
      end
    end
  rescue => e
    flash.now[:alert] = "Error al inicializar el formulario: #{e.message}"
  end

  def edit
    @purchase_payment = PurchasePayment.find(params[:id])
    @vendors = Purchases::Vendor.all
    
    # Get cashiers for dropdown
    @cashiers = Cashier.where(status: :active).order(:name)
    @cashiers_with_open_shifts = Cashier.active_with_open_shift.order(:name)
    
    # The cashier_shift will be set in update based on the selected cashier
    
    @elligible_payment_methods = PaymentMethod.active.where(payment_method_type: "standard")
    
    # Preselect the vendor if it exists
    @vendor_id = @purchase_payment.purchase&.vendor_id
    
    # Load purchases for the selected vendor
    @purchases = if @vendor_id.present?
      Purchases::Purchase.where(vendor_id: @vendor_id)
    else
      []
    end
  end

  def update
    # Extract cashier_id from params before updating the PurchasePayment
    cashier_id = params[:purchase_payment].delete(:cashier_id) if params[:purchase_payment][:cashier_id].present?
    
    @purchase_payment = PurchasePayment.find(params[:id])
    @vendors = Purchases::Vendor.all
    
    # Get cashiers for dropdown (in case of validation errors)
    @cashiers = Cashier.where(status: :active).order(:name)
    
    # Set the cashier_shift based on the extracted cashier_id
    if cashier_id.present?
      cashier = Cashier.find(cashier_id)
      @purchase_payment.cashier_shift = find_cashier_shift(cashier)
    end
    
    # Set the purchase from purchase_id
    if params[:purchase_payment][:purchase_id].present?
      @purchase_payment.purchase = Purchases::Purchase.find(params[:purchase_payment][:purchase_id])
    end
    
    # Handle vendor_id from the form
    if params[:vendor_id].present? && params[:purchase_payment][:payable_id].blank?
      @vendor_id = params[:vendor_id]
      @purchase_payment.vendor_id = @vendor_id
    end
    
    @elligible_payment_methods = PaymentMethod.active.where(payment_method_type: "standard")
    
    # Preselect the vendor if it exists
    @vendor_id = @purchase_payment.purchase&.vendor_id
    
    # Load purchases for the selected vendor
    @purchases = if @vendor_id.present?
      Purchases::Purchase.where(vendor_id: @vendor_id)
    else
      []
    end
    
    if @purchase_payment.update(purchase_payment_params.except(:cashier_id, :purchase_id))
      redirect_to admin_purchase_payments_path, notice: 'Pago actualizado exitosamente.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    # Extract cashier_id from params before creating the PurchasePayment
    cashier_id = params[:purchase_payment].delete(:cashier_id) if params[:purchase_payment][:cashier_id].present?
    
    # Validate cashier selection
    if cashier_id.blank?
      @purchase_payment = PurchasePayment.new(purchase_payment_params)
      @purchase_payment.errors.add(:base, "Debe seleccionar una caja para continuar")
      
      # Set up variables for the form
      @cashiers = Cashier.where(status: :active).order(:name)
      @cashiers_with_open_shifts = Cashier.active_with_open_shift.order(:name)
      @elligible_payment_methods = PaymentMethod.active.where(payment_method_type: "standard")
      @vendors = Purchases::Vendor.all
      
      # Handle purchase invoice if present
      if params[:purchase_invoice_id].present?
        @purchase_invoice = PurchaseInvoice.find(params[:purchase_invoice_id])
      elsif params[:purchase_payment][:payable_type] == "PurchaseInvoice" && params[:purchase_payment][:payable_id].present?
        @purchase_invoice = PurchaseInvoice.find_by(id: params[:purchase_payment][:payable_id])
      end
      
      # Handle vendor_id from the form
      if params[:vendor_id].present?
        @vendor_id = params[:vendor_id]
        @purchases = Purchases::Purchase.where(vendor_id: @vendor_id)
      end
      
      return render :new, status: :unprocessable_entity
    end
    
    @purchase_payment = PurchasePayment.new(purchase_payment_params)
    @purchase_payment.status = "paid"
    @purchase_payment.user = current_user
    @purchase_payment.region = @current_location.region if @current_location.present?
    
    # Handle payable type correctly - ensure we're using the correct namespace
    if @purchase_payment.payable_type == "PurchaseInvoice"
      # PurchaseInvoice is in the root namespace
      @purchase_payment.payable_type = "PurchaseInvoice"
    end

    # Get cashiers for dropdown (in case of validation errors)
    @cashiers = Cashier.where(status: :active).order(:name)
    @cashiers_with_open_shifts = Cashier.active_with_open_shift.order(:name)
    
    # Get payment methods for dropdown
    @elligible_payment_methods = PaymentMethod.active.where(payment_method_type: "standard")
    
    # Load vendors for dropdown
    @vendors = Purchases::Vendor.all
    
    # If we have a payable_id and payable_type for a purchase invoice, load the purchase invoice
    if @purchase_payment.payable_type == "PurchaseInvoice" && @purchase_payment.payable_id.present?
      @purchase_invoice = PurchaseInvoice.find_by(id: @purchase_payment.payable_id)
      @vendor = @purchase_invoice&.vendor
    end
    
    # Set the cashier_shift based on the extracted cashier_id
    if cashier_id.present?
      cashier = Cashier.find(cashier_id)
      @purchase_payment.cashier_shift = find_cashier_shift(cashier)
    end
    
    # Handle vendor_id from the form
    if params[:vendor_id].present? && @purchase_payment.payable_id.blank?
      @vendor_id = params[:vendor_id]
      @purchase_payment.vendor_id = @vendor_id
      @purchases = Purchases::Purchase.where(vendor_id: @vendor_id)
    end
    
    # Handle purchase invoice if present
    purchase_invoice_id = nil
    if params[:purchase_payment][:purchase_invoice_id].present?
      purchase_invoice_id = params[:purchase_payment][:purchase_invoice_id]
      @purchase_invoice = PurchaseInvoice.find(purchase_invoice_id)
    elsif params[:purchase_invoice_id].present?
      purchase_invoice_id = params[:purchase_invoice_id]
      @purchase_invoice = PurchaseInvoice.find(purchase_invoice_id)
    elsif session[:purchase_invoice_id].present?
      purchase_invoice_id = session[:purchase_invoice_id]
      @purchase_invoice = PurchaseInvoice.find(purchase_invoice_id)
    end

    ActiveRecord::Base.transaction do
      if @purchase_payment.save
        # Handle purchase invoice payment if applicable
        if purchase_invoice_id.present?
          purchase_invoice = PurchaseInvoice.find(purchase_invoice_id)
          
          # Calculate remaining balance
          remaining_balance = purchase_invoice.amount_cents - purchase_invoice.purchase_invoice_payments.sum(:amount_cents)
          
          # Determine amount to apply to this invoice
          amount_to_apply = [remaining_balance, @purchase_payment.amount_cents].min
          
          if amount_to_apply > 0
            # Create purchase invoice payment
            purchase_invoice_payment = PurchaseInvoicePayment.new(
              purchase_invoice: purchase_invoice,
              purchase_payment: @purchase_payment,
              amount_cents: amount_to_apply,
              currency: @purchase_payment.currency
            )
            
            unless purchase_invoice_payment.save
              raise ActiveRecord::Rollback, "Error al aplicar el pago a la factura: #{purchase_invoice_payment.errors.full_messages.join(', ')}"
            end
            
            # Associate the purchase payment with the purchase invoice
            @purchase_payment.update(purchase_invoice: purchase_invoice)
          end
          
          # Clear the session
          session.delete(:purchase_invoice_id)
          
          redirect_to admin_account_payables_path(vendor_id: purchase_invoice.vendor_id), notice: "Pago creado y aplicado a la factura exitosamente"
        else
          redirect_to admin_purchase_payments_path, notice: "Pago creado exitosamente"
        end
      else
        # Ensure we have all necessary variables for the form
        if params[:vendor_id].present?
          @vendor_id = params[:vendor_id]
          @purchases = Purchases::Purchase.where(vendor_id: @vendor_id)
        end
        
        # If we have a payable_id and payable_type for a purchase, load the purchase
        if @purchase_payment.payable_id.present? && @purchase_payment.payable_type == "Purchases::Purchase"
          @purchase = Purchases::Purchase.find_by(id: @purchase_payment.payable_id)
        end
        
        render :new, status: :unprocessable_entity
      end
    end
  rescue => e
    # Ensure we have all necessary variables for the form on exception
    if params[:vendor_id].present?
      @vendor_id = params[:vendor_id]
      @purchases = Purchases::Purchase.where(vendor_id: @vendor_id)
    end
    
    # If we have a payable_id and payable_type for a purchase, load the purchase
    if params[:purchase_payment] && params[:purchase_payment][:payable_id].present? && 
       params[:purchase_payment][:payable_type] == "Purchases::Purchase"
      @purchase = Purchases::Purchase.find_by(id: params[:purchase_payment][:payable_id])
    end
    
    flash.now[:alert] = "Error al crear el pago: #{e.message}"
    render :new, status: :unprocessable_entity
  end

  private

  def find_cashier_shift(cashier)
    # Try to find an open shift for this cashier
    open_shift = cashier.cashier_shifts.where(status: :open).order(opened_at: :desc).first  
    # Save the new shift
    unless open_shift.present? && open_shift.save
      raise "No se pudo encontrar un turno de caja abierto para el cajero: #{cashier.name}"
    end
    
    open_shift
  end

  def purchase_payment_params
    params.require(:purchase_payment).permit(
      :purchase_id, 
      :payment_method_id, 
      :amount, 
      :payment_date, 
      :description, 
      :comment,
      :cashier_shift_id,
      :payable_id,
      :payable_type,
      :purchase_invoice_id,
      :vendor_id,
      :processor_transacion_id
    )
  end

  def datatable_json
    purchase_payments = PurchasePayment.includes(:payable, cashier_shift: :cashier)
                                      .joins(:payment_method)

    # Location filter
    if @current_location && current_user.any_admin_or_supervisor?
      purchase_payments = purchase_payments.where(region_id: @current_location.region_id)
    end

    # Apply search filter
    if params[:search][:value].present?
      purchase_payments = purchase_payments.where("purchase_payments.custom_id ILIKE ? OR purchase_payments.description ILIKE ?", 
                                                "%#{params[:search][:value]}%", "%#{params[:search][:value]}%")
    end

    # Apply sorting
    if params[:order].present?
      column_index = params[:order]["0"][:column].to_i
      direction = params[:order]["0"][:dir]

      order_clause = case column_index
      when 0
        [ "purchase_payments.custom_id", direction ]
      when 1
        [ "purchase_payments.payment_date", direction ]
      when 2
        [ "purchase_payments.payable_type", direction ]
      when 3
        [ "cashiers.name", direction ]
      when 4
        [ "purchase_payments.amount_cents", direction ]
      when 5
        [ "purchase_payments.processor_transacion_id", direction ]
      when 6
        [ "purchase_payments.status", direction ]
      when 7
        [ "purchase_payments.payable_id", direction ]
      else
        [ "purchase_payments.id", "DESC" ]
      end

      if order_clause.present?
        purchase_payments = purchase_payments.order(Arel.sql("#{order_clause[0]} #{order_clause[1]}"))
      end
    else
      purchase_payments = purchase_payments.order(id: :desc) # Default sorting
    end

    # Pagination
    paginated_payments = purchase_payments.offset(params[:start].to_i).limit(params[:length].to_i)

    {
      draw: params[:draw].to_i,
      recordsTotal: PurchasePayment.count,
      recordsFiltered: purchase_payments.count,
      data: paginated_payments.map do |payment|
        row = []

        # Fix any incorrect payable_type values
        payment.payable_type = "PurchaseInvoice" if payment.payable_type == "Purchases::PurchaseInvoice"

        vendor_name = if payment.vendor.present?
                        payment.vendor.name
                      elsif payment.payable_type == "Purchases::Purchase"
                        payment.payable&.vendor&.name
                      elsif payment.payable_type == "Purchases::Vendor"
                        payment.payable&.name
                      elsif payment.payable_type == "PurchaseInvoice"
                        payment.payable&.vendor&.name
                      else
                        ""
                      end

        row.concat([
          payment.custom_id,
          payment.payment_date&.strftime("%d/%m/%Y"),
          vendor_name,
          payment.cashier_shift&.cashier&.name,
          format_currency(payment.amount),
          payment.processor_transacion_id,
          payment.translated_status,
          payment.payable&.custom_id,
          view_context.link_to("Ver", admin_purchase_payment_path(payment), class: "text-indigo-600 hover:text-indigo-900")
        ])

        row
      end
    }
  end
end
