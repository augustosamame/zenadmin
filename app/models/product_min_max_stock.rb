class ProductMinMaxStock < ApplicationRecord
  belongs_to :product
  belongs_to :warehouse

  has_many :product_min_max_period_multipliers, dependent: :destroy

  accepts_nested_attributes_for :product_min_max_period_multipliers, allow_destroy: true, reject_if: :all_blank
end
