class Order < ApplicationRecord
  audited_if_enabled

  include DefaultRegionable
  include CustomNumberable
  include PgSearch::Model

  belongs_to :region
  belongs_to :user
  belongs_to :seller, class_name: "User"
  belongs_to :location

  enum :stage, { draft: 0, confirmed: 1, shipped: 2, delivered: 3, cancelled: 4 }
  enum :payment_status, { unpaid: 0, paid: 1, partially_paid: 2 }
  enum :origin, { pos: 0, ecommerce: 1 }
  enum :status, { active: 0, inactive: 1 }

  monetize :total_price_cents, with_model_currency: :currency
  monetize :total_discount_cents, with_model_currency: :currency
  monetize :shipping_price_cents, with_model_currency: :currency

  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items
  has_many :payments, as: :payable, dependent: :destroy

  has_many :commissions, dependent: :destroy
  has_many :commission_payouts, through: :commissions
  has_many :sellers, through: :commissions, source: :user

  before_create :set_defaults

  # Update commissions when the order is marked as paid
  after_commit :update_commissions_status, if: :paid?

  validates :user_id, :location_id, :region_id, presence: true
  validates :total_price_cents, presence: true
  validates :currency, presence: true

  accepts_nested_attributes_for :order_items, allow_destroy: true
  accepts_nested_attributes_for :payments, allow_destroy: true

  pg_search_scope :search_by_customer_name,
                  associated_against: {
                    user: [ :first_name, :last_name ] # Assuming the customer user has first_name and last_name fields
                  },
                  using: {
                    tsearch: { prefix: true }
                  }

  attr_accessor :sellers_attributes

  def total_items
    order_items.sum(:quantity)
  end

  def total_items_by_product_id(product_id)
    order_items.where(product_id: product_id).sum(:quantity)
  end

  def customer
    user
  end

  def set_defaults
    order_date = Time.zone.now
  end

  private

    def update_commissions_status
      commissions.status_order_unpaid.update_all(status: :status_order_paid)
    end
end
