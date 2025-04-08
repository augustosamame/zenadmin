class CashierShift < ApplicationRecord
  include TranslateEnum

  belongs_to :cashier
  belongs_to :opened_by, class_name: "User"
  belongs_to :closed_by, class_name: "User", optional: true

  has_many :cashier_transactions, dependent: :restrict_with_error
  has_many :payments, through: :cashier_transactions, source: :transactable, source_type: "Payment"
  has_many :cash_inflows, through: :cashier_transactions, source: :transactable, source_type: "CashInflow"
  has_many :cash_outflows, through: :cashier_transactions, source: :transactable, source_type: "CashOutflow"

  has_one :location, through: :cashier

  enum :status, { open: 0, closed: 1 }
  translate_enum :status

  validates :date, presence: true
  validates :status, presence: true
  validates :total_sales_cents, numericality: { greater_than_or_equal_to: 0 }

  before_create :check_if_shift_is_open

  attr_accessor :retroactive_order_override

  def check_if_shift_is_open
    if cashier.cashier_shifts.open.exists? && !retroactive_order_override
      errors.add(:base, "Ya hay un turno de caja abierto para este cajero: #{cashier.name}.")
      throw(:abort)
    end
  end

  def sales_by_seller
    # First, get all distinct payment_id, user_id combinations with percentage
    payment_seller_pairs = Order.joins(:payments)
                              .joins("LEFT JOIN commissions ON commissions.order_id = orders.id")
                              .where(payments: { cashier_shift_id: self.id })
                              .select("payments.id, commissions.user_id, payments.amount_cents, commissions.percentage")

    # Then, group by user_id and sum the amounts
    result = {}
    payment_seller_pairs.each do |pair|
      next unless pair.user_id # Skip if no user_id (could happen with LEFT JOIN)

      user_id = pair.user_id
      # If percentage is available, use it, otherwise default to 1.0 (100%)
      raw_percentage = pair.percentage.present? ? pair.percentage.to_f : 100.0

      # Special case handling for 33%
      raw_percentage = 33.3333 if raw_percentage == 33.0

      percentage = raw_percentage / 100.0
      amount = (pair.amount_cents.to_f / 100.0) * percentage

      result[user_id] ||= 0
      result[user_id] += amount
    end

    result
  end

  def total_balance
    # Use the cashier_transactions and their amount_for_balance method to get the correct balance
    balance_cents = cashier_transactions.reject { |transaction| transaction.payment_method.name == "credit" }.sum do |transaction|
      transaction.amount_for_balance
    end

    Money.new(balance_cents, "PEN")
  end

  def daily_balance
    total_balance - Money.new(cash_from_previous_shift_cents, "PEN")
  end

  def cash_from_previous_shift_cents
    self.cash_inflows.where(description: "Saldo de caja anterior - Efectivo").sum(:amount_cents)
  end

  def total_ruc_sales
    total_cents = payments.includes(payable: []).sum do |payment|
      order = payment.payable
      if order.is_a?(Order) && order.invoice&.invoicer&.tipo_ruc == "RUC"
        payment.amount_cents
      else
        0
      end
    end
    Money.new(total_cents, "PEN")
  end

  def total_rus_sales
    total_cents = payments.includes(payable: []).sum do |payment|
      order = payment.payable
      if order.is_a?(Order) && order.invoice&.invoicer&.tipo_ruc == "RUS"
        payment.amount_cents
      else
        0
      end
    end
    Money.new(total_cents, "PEN")
  end

  def self.reset_all_saldo_inicial
    # Use a direct SQL approach to avoid the media association issue
    ActiveRecord::Base.transaction do
      # First, get all CashInflow IDs that match our criteria
      inflow_ids = CashInflow.where("description LIKE ?", "Saldo de caja anterior -%").pluck(:id)
      
      if inflow_ids.any?
        # Delete associated cashier transactions first
        CashierTransaction.where(transactable_type: 'CashInflow', transactable_id: inflow_ids).delete_all
        
        # Then delete the cash inflows directly
        CashInflow.where(id: inflow_ids).delete_all
        
        puts "Successfully deleted #{inflow_ids.count} CashInflow records"
      else
        puts "No CashInflow records found matching 'Saldo de caja anterior -'"
      end
    end
    
    # Now proceed with adding new balances
    Cashier.all.each do |cashier|
      cashier.cashier_shifts.order(id: :asc).each do |cashier_shift|
        # Skip the deletion part since we've already done it
        cashier_shift.add_previous_balance
      end
    end
  end
  
  # New method to add previous balance without trying to delete first
  def add_previous_balance
    cashier_shift = self
    # Get the last shift for this cashier, regardless of status
    last_shift = cashier_shift.cashier.cashier_shifts.where("id < ?", cashier_shift.id).order(id: :desc).first
    if last_shift
      total_amount_cents = last_shift.total_balance.cents
      CashierTransaction.create!(
        cashier_shift: cashier_shift,
        amount_cents: total_amount_cents,
        payment_method: PaymentMethod.find_by(name: "cash"),
        created_at: last_shift.created_at - 1.second,
        updated_at: last_shift.created_at - 1.second,
        transactable: CashInflow.new(
          cashier_shift: cashier_shift, # Ensure the cashier_shift is set
          amount_cents: total_amount_cents,
          received_by: cashier_shift.opened_by,
          description: "Saldo de caja anterior - #{PaymentMethod.find_by(name: "cash")&.description || 'Sin método de pago'}"
        )
      )
    end
  end
  
  # Keep the original method but modify it to use the new approach
  def reset_saldo_inicial
    # First delete any existing "Saldo de caja anterior" records using direct SQL
    inflow_ids = self.cash_inflows.where("description LIKE ?", "Saldo de caja anterior -%").pluck(:id)
    if inflow_ids.any?
      CashierTransaction.where(transactable_type: 'CashInflow', transactable_id: inflow_ids).delete_all
      CashInflow.where(id: inflow_ids).delete_all
    end
    
    # Then add the new balance
    add_previous_balance
  end

  def self.automatic_close_all_shifts
    closed_by_user = User.first_admin_or_superadmin_user
    Location.all.each do |location|
      location.cashiers.each do |cashier|
        next if cashier.cashier_type == "bank"
        cashier.cashier_shifts.open.each do |open_shift|
          Services::Sales::CashierTransactionService.new(open_shift).close_shift(closed_by_user)
        end
      end
    end
  end

  def reset_payment_methods_all_cashiers
    cash_payment_method = PaymentMethod.find_by(name: "cash")
    Cashier.all.includes(:cashier_shifts).each do |cashier|
      cashier.cashier_shifts.each do |cashier_shift|
        if cashier.cashier_type == "standard"
          cashier_shift.cashier_transactions.each do |cashier_transaction|
            case cashier_transaction.payment_method.name
            when "cash", "credit"
              next
            else
              cashier_transaction.update_columns(payment_method_id: cash_payment_method.id)
            end
          end
        end
        if cashier.cashier_type == "bank"
          cashier_shift.cashier_transactions.each do |cashier_transaction|
            case cashier_transaction.payment_method.name
            when "cash"
              next
            else
              cashier_transaction.update_columns(payment_method_id: cash_payment_method.id)
            end
          end
        end
      end
    end
  end
end
