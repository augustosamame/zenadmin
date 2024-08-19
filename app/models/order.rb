class Order < ApplicationRecord
  include DefaultRegionable

  belongs_to :region
  belongs_to :user
  belongs_to :location

  enum :stage, { draft: 0, confirmed: 1, shipped: 2, delivered: 3, cancelled: 4 }
  enum :payment_status, { unpaid: 0, paid: 1, partially_paid: 2 }
  enum :status, { active: 0, inactive: 1 }

  monetize :total_price_cents, with_model_currency: :currency
  monetize :total_discount_cents, with_model_currency: :currency
  monetize :shipping_price_cents, with_model_currency: :currency

  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  validates :user_id, :location_id, :region_id, presence: true
  validates :total_price_cents, presence: true
  validates :currency, presence: true

  accepts_nested_attributes_for :order_items, allow_destroy: true

  def total_items
    order_items.sum(:quantity)
  end

  def total_items_by_product_id(product_id)
    order_items.where(product_id: product_id).sum(:quantity)
  end
end
