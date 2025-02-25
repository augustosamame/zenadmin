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
    Order.joins(:payments)
         .joins("LEFT JOIN commissions ON commissions.order_id = orders.id")
         .where(payments: { cashier_shift_id: self.id })
         .group("commissions.user_id")
         .sum("(payments.amount_cents / 100.0)")
         .transform_values { |cents| cents.to_f }
  end

  def total_balance
    total_payments = Money.new(payments.sum(:amount_cents), "PEN")
    total_inflows = Money.new(cash_inflows.sum(:amount_cents), "PEN")
    total_outflows = Money.new(cash_outflows.sum(:amount_cents), "PEN")

    total_payments + total_inflows - total_outflows
  end

  def daily_balance
    total_balance - Money.new(cash_from_previous_shift_cents, "PEN")
  end

  def cash_from_previous_shift_cents
    self.cash_inflows.where(description: "Saldo de caja anterior - Efectivo").sum(:amount_cents)
  end

  def self.automatic_close_all_shifts
    closed_by_user = User.find_by!(email: "almacen_principal@jardindelzen.com")
    Location.all.each do |location|
      location.cashiers.each do |cashier|
        cashier.cashier_shifts.open.each do |open_shift|
          Services::Sales::CashierTransactionService.new(open_shift).close_shift(closed_by_user)
        end
      end
    end
  end
end
