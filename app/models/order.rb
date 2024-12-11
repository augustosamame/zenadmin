class Order < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  include DefaultRegionable
  include CustomNumberable
  include PgSearch::Model

  belongs_to :region
  belongs_to :user
  belongs_to :seller, class_name: "User"
  belongs_to :location

  enum :stage, { draft: 0, confirmed: 1, shipped: 2, delivered: 3, cancelled: 4 }
  translate_enum :stage
  enum :payment_status, { unpaid: 0, paid: 1, partially_paid: 2 }
  translate_enum :payment_status
  enum :origin, { pos: 0, ecommerce: 1 }
  enum :status, { active: 0, inactive: 1 }
  translate_enum :status

  monetize :total_price_cents, with_model_currency: :currency
  monetize :total_original_price_cents, with_model_currency: :currency
  monetize :total_discount_cents, with_model_currency: :currency
  monetize :shipping_price_cents, with_model_currency: :currency

  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items
  has_many :payments, as: :payable, dependent: :destroy
  has_many :account_receivables, dependent: :destroy

  has_many :commissions, dependent: :destroy
  has_many :commission_payouts, through: :commissions
  has_many :sellers, through: :commissions, source: :user

  has_many :invoices, dependent: :destroy
  has_many :external_invoices, dependent: :destroy
  has_many :preorders, dependent: :destroy

  has_many :notifications, as: :notifiable, dependent: :destroy

  before_create :set_defaults

  after_commit :create_notification
  after_create_commit :refresh_dashboard_metrics
  after_commit :evaluate_payment_status, on: [ :create ]
  after_commit :reevaluate_payment_status, on: [ :update ]

  validates :user_id, :location_id, :region_id, presence: true
  validates :total_price_cents, presence: true
  validates :total_original_price_cents, presence: true
  validates :currency, presence: true

  accepts_nested_attributes_for :order_items, allow_destroy: true
  accepts_nested_attributes_for :payments, allow_destroy: true
  accepts_nested_attributes_for :commissions, allow_destroy: true

  scope :unpaid_or_partially_paid, -> { where(payment_status: [ :unpaid, :partially_paid ]) }

  pg_search_scope :search_by_customer_name_or_total_or_invoice_number,
    against: [ :custom_id, :total_price_cents ],
    associated_against: {
      user: [ :first_name, :last_name ],
      invoices: [ :custom_id ],
      external_invoices: [ :custom_id ]
    },
    using: {
      tsearch: {
        prefix: true,
        any_word: true,
        dictionary: "spanish"
      }
    }

  pg_search_scope :search_consolidated_sales,
    against: [ :custom_id ],
    associated_against: {
      user: [ :first_name, :last_name ],
      invoices: [ :custom_id ],
      external_invoices: [ :custom_id ]
    },
    using: {
      tsearch: {
        prefix: true,
        any_word: true,
        dictionary: "spanish"
      }
    }

  attr_accessor :sellers_attributes, :invoice_series_comprobante_type

  def refresh_dashboard_metrics
    broadcast_refresh_to "sales_dashboard", target: "sales_count"
    broadcast_refresh_to "sales_dashboard", target: "sales_amount"
    broadcast_refresh_to "sales_dashboard", target: "sales_amount_this_month"
  end

  def total_items
    order_items.sum(:quantity)
  end

  def total_items_by_product_id(product_id)
    order_items.where(product_id: product_id).sum(:quantity)
  end

  def customer
    Customer.find_by(user_id: self.user_id)&.user
  end

  def set_defaults
    self.order_date ||= Time.zone.now
  end

  def universal_invoice_link
    "#{ENV["DOMAIN_URL"]}/invoice/#{self.id}"
  end

  def universal_xml_link
    "#{ENV["DOMAIN_URL"]}/invoice_xml/#{self.id}"
  end

  def universal_invoice_show
    if self.last_issued_ok_invoice_urls.present?
      {
        message: nil,
        url: self.last_issued_ok_invoice_urls.last[1],
        status: :ready
      }
    else
      {
        message: "El comprobante aún está siendo generado. Por favor, inténtelo de nuevo más tarde.",
        url: nil,
        status: :pending
      }
    end
  end

  def update_loyalty_tier
    Services::Sales::LoyaltyTierService.new(self.user).update_loyalty_tier
  end

  def update_free_product_availability
    if self.order_items.any? { |item| item.is_loyalty_free.present? }
      Services::Sales::LoyaltyTierService.new(self.user).update_free_product_availability(self)
    end
  end

  def determine_order_invoices_matrix
    Services::Sales::OrderInvoiceService.new(self).determine_order_invoices_matrix
  end

  def last_issued_ok_invoice_urls
    self.invoices.where(status: "issued", sunat_status: "sunat_success").pluck(:custom_id, :invoice_url)
  end

  def invoice
    self.invoices&.sunat_success&.issued&.last
  end

  def evaluate_payment_status
    Services::Sales::OrderCreditService.new(self).evaluate_payment_status(operation: :create)
  end

  def reevaluate_payment_status
    Services::Sales::OrderCreditService.new(self).evaluate_payment_status(operation: :update)
  end

  def order_is_paid_activities
    update_commissions_status if $global_settings[:feature_flag_sales_attributed_to_seller]
    update_loyalty_tier if $global_settings[:feature_flag_loyalty_program]
    update_free_product_availability if $global_settings[:feature_flag_loyalty_program]
  end

  def update_commissions_status
    commissions.status_order_unpaid.update_all(status: :status_order_paid)
  end

  def einvoice_comments
    text = ""
    begin
      text += "Vendedor: #{self.sellers&.first&.name} - " if self.sellers&.first&.present?
      text += "Medio de Pago: #{self.main_payment_method}" if self.main_payment_method.present?
      text
    rescue StandardError => e
      Rails.logger.error "Error generating einvoice_comments for order #{id}: #{e.message}"
      ""
    end
  end

  def self.consolidated_sales(location: nil, date_range: nil, order_column: nil, order_direction: nil, search_term: nil)
    # First get the regular sales data
    base_query = Order.select("orders.*")
                   .joins("INNER JOIN locations ON locations.id = orders.location_id")
                   .joins("INNER JOIN users ON users.id = orders.user_id")
                   .joins("LEFT JOIN payments ON payments.payable_id = orders.id AND payments.payable_type = 'Order'")
                   .joins("LEFT JOIN payment_methods ON payment_methods.id = payments.payment_method_id")
                   .joins("LEFT JOIN invoices ON invoices.order_id = orders.id")
                   .joins("LEFT JOIN external_invoices ON external_invoices.order_id = orders.id")

    base_query = base_query.where(location: location) if location
    if date_range
      start_date = date_range.begin.in_time_zone("America/Lima").beginning_of_day.utc
      end_date = date_range.end.in_time_zone("America/Lima").end_of_day.utc
      base_query = base_query.where("orders.order_date BETWEEN ? AND ?", start_date, end_date)
    end
    base_query = base_query.search_consolidated_sales(search_term) if search_term.present?

    # Execute the query with all columns we need
    sales_data = base_query.select([
      "orders.id",
      "locations.name as location_name",
      "orders.custom_id as order_custom_id",
      "orders.order_date as order_datetime",
      "CONCAT(users.first_name, ' ', users.last_name) as customer_name",
      "orders.total_price_cents as order_total",
      "payment_methods.description as payment_method",
      "payments.amount_cents as payment_total",
      "payments.processor_transacion_id as payment_tx",
      "COALESCE(invoices.custom_id, external_invoices.custom_id) as invoice_custom_id",
      "invoices.sunat_status as invoice_status",
      "COALESCE(invoices.invoice_url, external_invoices.invoice_url) as invoice_url"
    ].join(", "))

    # Add ordering if specified
    if order_column.present? && order_direction.present?
      order_sql = case order_column
      when "1" # custom_id
                    "orders.custom_id"
      when "2" # datetime
                    "orders.order_date"
      when "4" # total
                    "orders.total_price_cents"
      else
                    "orders.custom_id"
      end

      direction = order_direction.upcase
      return sales_data.order(Arel.sql("#{order_sql} #{direction}"))
    end

    sales_data.order(Arel.sql("orders.custom_id DESC"))
  end

  private

    def create_notification
      Services::Notifications::CreateNotificationService.new(self).create
    end

    def main_payment_method
      self.payments.where(status: :paid).order(amount_cents: :desc).first&.payment_method&.description
    end
end
