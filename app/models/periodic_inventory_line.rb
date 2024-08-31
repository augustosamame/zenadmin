class PeriodicInventoryLine < ApplicationRecord
  belongs_to :periodic_inventory
  belongs_to :product

  enum :status, { active: 0, inactive: 1 }

  validates :stock, presence: true
end
