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

  has_many :commissions, dependent: :destroy
  has_many :commission_payouts, through: :commissions
  has_many :sellers, through: :commissions, source: :user

  has_many :invoices, dependent: :destroy

  has_many :preorders, dependent: :destroy

  before_create :set_defaults

  # Update commissions when the order is marked as paid
  after_commit :update_commissions_status, if: :paid?
  after_commit :update_loyalty_tier, if: :paid?, on: [ :create, :update, :destroy ]
  after_commit :update_free_product_availability, if: :paid?, on: [ :create ]
  after_commit :create_notification
  after_create_commit :refresh_dashboard_metrics


  validates :user_id, :location_id, :region_id, presence: true
  validates :total_price_cents, presence: true
  validates :total_original_price_cents, presence: true
  validates :currency, presence: true

  accepts_nested_attributes_for :order_items, allow_destroy: true
  accepts_nested_attributes_for :payments, allow_destroy: true
  accepts_nested_attributes_for :commissions, allow_destroy: true

  pg_search_scope :search_by_customer_name,
                  associated_against: {
                    user: [ :first_name, :last_name ] # Assuming the customer user has first_name and last_name fields
                  },
                  using: {
                    tsearch: { prefix: true }
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

  private

    def update_commissions_status
      commissions.status_order_unpaid.update_all(status: :status_order_paid)
    end

    def create_notification
      Services::Notifications::CreateNotificationService.new(self).create
    end
end
