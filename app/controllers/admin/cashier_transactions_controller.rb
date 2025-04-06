class Admin::CashierTransactionsController < Admin::AdminController
  before_action :initialize_cashier_transaction, only: [ :new, :create ]
  before_action :build_transactable, only: [ :new, :create ]

  def new
    load_form_dependencies
  end

  def create
    @cashier_shift = if params[:cashier_shift_id].present?
      CashierShift.find(params[:cashier_shift_id])
    else
      @current_cashier_shift
    end
    @cashier_transaction.cashier_shift = @cashier_shift
    @cashier_transaction.currency = "PEN"

    if @cashier_transaction.transactable.present?
      @cashier_transaction.transactable.currency = "PEN"
      
      # Set description based on transactable type
      case @cashier_transaction.transactable_type
      when "CashOutflow"
        # Check if this is a cashier-to-cashier transfer
        if $global_settings[:feature_flag_bank_cashiers_active] && params[:transactable][:paid_to_id].to_s.start_with?('cashier_')
          # Extract the target cashier ID and get the cashier
          target_cashier_id = params[:transactable][:paid_to_id].to_s.gsub('cashier_', '').to_i
          target_cashier = Cashier.find_by(id: target_cashier_id)
          
          if target_cashier
            @cashier_transaction.transactable.description += " - Transferencia a #{target_cashier.name}"
            # Set the target_cashier_id attribute
            @cashier_transaction.transactable.target_cashier_id = params[:transactable][:paid_to_id]
          end
        else
          # Regular user payment
          paid_to_name = @cashier_transaction.transactable.paid_to&.name
          @cashier_transaction.transactable.description += " - Pagado a #{paid_to_name}" if paid_to_name.present?
        end
      end
    end

    if @cashier_transaction.save
      # If this is a cashier-to-cashier transfer, create the corresponding inflow
      if $global_settings[:feature_flag_bank_cashiers_active] && 
         @cashier_transaction.transactable_type == "CashOutflow" && 
         (@cashier_transaction.transactable.target_cashier_id.present? || 
          @cashier_transaction.transactable.paid_to_id.to_s.start_with?('cashier_'))
        
        # Pass the target_cashier_id to the service
        target_id = @cashier_transaction.transactable.target_cashier_id || 
                    @cashier_transaction.transactable.paid_to_id
        
        CashierTransferService.process_cashier_transfer(@cashier_transaction.transactable, target_id)
      end
      
      redirect_to admin_cashier_shift_path(@cashier_transaction.cashier_shift), notice: "Transacción registrada exitosamente."
    else
      load_form_dependencies
      render :new, status: :unprocessable_entity
    end
  end

  private

  def load_form_dependencies
    @cashier_shift = if params[:cashier_shift_id].present?
      CashierShift.find(params[:cashier_shift_id])
    elsif params[:format].present?
      CashierShift.find(params[:format])
    else
      @current_cashier_shift
    end
    
    # Set eligible payment methods based on cashier type and transaction type
    if @cashier_shift.cashier.cashier_type == "bank"
      # For bank cashiers, only allow cash payment method for both cashout and cashin
      if params[:transactable_type] == 'CashOutflow' || params[:transactable_type] == 'CashInflow'
        @elligible_payment_methods = PaymentMethod.where(name: "cash")
      else
        # For other transaction types, use the cashier name as the payment method
        @elligible_payment_methods = PaymentMethod.where(description: @cashier_shift.cashier.name)
      end
    else
      # For standard cashiers
      if params[:transactable_type] == 'CashOutflow' || params[:transactable_type] == 'CashInflow'
        # For cashouts and cashins, exclude bank and credit type payment methods
        excluded_types = [:bank, :credit]
        @elligible_payment_methods = PaymentMethod.where.not(payment_method_type: excluded_types)
      else
        # For other transaction types, allow all payment methods
        @elligible_payment_methods = PaymentMethod.all
      end
    end
    
    # Base eligible users (existing functionality)
    @elligible_users = User.with_any_role(:admin, :super_admin, :supervisor, :money_recipient)
    
    # Add cashiers to eligible users if the feature flag is enabled and this is a CashOutflow
    if $global_settings[:feature_flag_bank_cashiers_active] && params[:transactable_type] == 'CashOutflow'
      # Get active cashiers excluding the current one
      active_cashiers = Cashier.where(status: :active).where.not(id: @cashier_shift.cashier_id)
      
      # Create virtual users for each cashier
      cashier_users = active_cashiers.map do |cashier|
        OpenStruct.new(
          id: "cashier_#{cashier.id}",
          name: "Caja: #{cashier.name}"
        )
      end
      
      # Combine regular users with cashier "users"
      @elligible_users = (@elligible_users.to_a + cashier_users)
    end
  end

  def initialize_cashier_transaction
    @cashier_transaction = CashierTransaction.new(cashier_transaction_params)
    @cashier_transaction.currency ||= "PEN"
    if params[:transactable].present? && params[:transactable][:processor_transacion_id].present?
      @cashier_transaction.processor_transacion_id = params[:transactable][:processor_transacion_id]
    end
  end

  def cashier_transaction_params
    params.fetch(:cashier_transaction, {}).permit(:amount, :transactable_type, :payment_method_id, :currency, :processor_transacion_id)
  end

  def build_transactable
    return unless params[:transactable_type].present?

    transactable_class = safe_constantize(params[:transactable_type])
    return unless transactable_class

    transactable_params = filtered_transactable_params.merge(currency: "PEN")
    
    # For CashOutflow with cashier transfer, we need special handling
    if transactable_class == CashOutflow && 
       $global_settings[:feature_flag_bank_cashiers_active] && 
       transactable_params[:paid_to_id].to_s.start_with?('cashier_')
      # Store the cashier ID in the target_cashier_id attribute
      transactable_params[:target_cashier_id] = transactable_params[:paid_to_id]
      # Set paid_to_id to nil to bypass the validation
      transactable_params[:paid_to_id] = nil
    end
    
    @cashier_transaction.transactable ||= transactable_class.new(transactable_params)
    assign_transactable_attributes
  end

  def assign_transactable_attributes
    @cashier_transaction.transactable.tap do |transactable|
      transactable.currency = "PEN"  # Set currency first
      transactable.cashier_shift = @current_cashier_shift
      transactable.amount_cents = @cashier_transaction.amount_cents
      transactable.processor_transacion_id = @cashier_transaction.processor_transacion_id
      
      # For CashOutflow with cashier transfer, ensure we store the cashier ID
      if transactable.is_a?(CashOutflow) && 
         $global_settings[:feature_flag_bank_cashiers_active] && 
         transactable.target_cashier_id.present?
        # Store the cashier ID in an instance variable to use later
        transactable.instance_variable_set(:@target_cashier_id, transactable.target_cashier_id)
      end
    end
  end

  def filtered_transactable_params
    case params[:transactable_type]
    when "CashInflow"
      params.fetch(:transactable, {}).permit(
        :processor_transacion_id,
        :received_by_id,
        :description,
        :currency
      )
    when "CashOutflow"
      # For CashOutflow, we need to handle both regular users and cashier transfers
      # The paid_to_id could be a regular user ID or a string like "cashier_123"
      outflow_params = params.fetch(:transactable, {}).permit(
        :processor_transacion_id,
        :paid_to_id,
        :description,
        :currency,
        :target_cashier_id  # Add the target_cashier_id to permitted params
      )
      
      outflow_params
    else
      {}
    end
  end

  private

    def safe_constantize(class_name)
      allowed_classes = [ "Payment", "CashInflow", "CashOutflow" ] # Add all allowed class names
      class_name.in?(allowed_classes) ? class_name.constantize : nil
    end
end
