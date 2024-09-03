class PeriodicInventory < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  belongs_to :warehouse
  belongs_to :user
  has_many :periodic_inventory_lines, dependent: :destroy
  has_many :stock_transfers, dependent: :restrict_with_error
  has_many :products, through: :periodic_inventory_lines

  enum :status, { active: 0, inactive: 1 }
  translate_enum :status
  enum :inventory_type, { manual: 0, automatic: 1 }
  translate_enum :inventory_type

  validates :snapshot_date, presence: true

  accepts_nested_attributes_for :periodic_inventory_lines, allow_destroy: true

  def total_products
    periodic_inventory_lines.sum(:quantity)
  end
end
