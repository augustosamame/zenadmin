class ProductMinMaxPeriodMultiplier < ApplicationRecord
  belongs_to :product_min_max_stock

  validates :period, :multiplier, presence: true
  validates :multiplier, numericality: { greater_than: 0 }
  validates :period, uniqueness: { scope: :product_min_max_stock_id }
end
