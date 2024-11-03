class PeriodicInventory < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  belongs_to :warehouse
  belongs_to :user
  has_many :periodic_inventory_lines, dependent: :destroy
  has_many :stock_transfers, dependent: :restrict_with_error
  has_many :products, through: :periodic_inventory_lines

  has_many :notifications, as: :notifiable, dependent: :destroy


  enum :status, { active: 0, inactive: 1 }
  translate_enum :status
  enum :inventory_type, { manual: 0, automatic: 1 }
  translate_enum :inventory_type

  validates :snapshot_date, presence: true

  accepts_nested_attributes_for :periodic_inventory_lines, allow_destroy: true

  def total_products
    periodic_inventory_lines.sum(:quantity)
  end

  def object_identifier
    "#{warehouse.name} - #{I18n.l(snapshot_date, format: :short)}"
  end

  # Add this method to get all differences
  def differences
    stock_transfers.includes(stock_transfer_lines: :product).flat_map do |transfer|
      transfer.stock_transfer_lines.map do |line|
        {
          product: line.product,
          quantity: line.quantity
        }
      end
    end
  end
end
