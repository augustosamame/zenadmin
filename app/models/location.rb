class Location < ApplicationRecord
  audited_if_enabled

  include DefaultRegionable

  belongs_to :region
  has_many :warehouses
  has_many :users
  has_many :cashiers, dependent: :destroy
  has_many :commission_ranges, dependent: :destroy
  has_many :orders

  validates :name, presence: true
  validates :email, presence: true

  accepts_nested_attributes_for :commission_ranges, reject_if: :all_blank, allow_destroy: true

  enum :status, [ :active, :inactive ]

  def sales_on_month
    self.orders.active.where(order_date: Time.now.beginning_of_month..Time.now.end_of_month).sum(:total_price_cents)
  end

  def sales_on_month_by_seller
    self.orders.active.where(order_date: Time.now.beginning_of_month..Time.now.end_of_month).group(:seller_id).sum(:total_price_cents)
  end

  def sales_on_year
    self.orders.active.where(order_date: Time.now.beginning_of_year..Time.now.end_of_year).sum(:total_price_cents)
  end

  def sales_on_year_by_seller
    self.orders.active.where(order_date: Time.now.beginning_of_year..Time.now.end_of_year).group(:seller_id).sum(:total_price_cents)
  end
end
