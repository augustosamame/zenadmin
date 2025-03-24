class PlannedStockTransfer < ApplicationRecord
  include AASM
  include CustomNumberable
  include TranslateEnum

  belongs_to :user
  belongs_to :origin_warehouse, class_name: "Warehouse", optional: true
  belongs_to :destination_warehouse, class_name: "Warehouse", optional: true
  belongs_to :order, optional: true

  has_many :planned_stock_transfer_lines, dependent: :destroy
  has_many :products, through: :planned_stock_transfer_lines
  has_many :stock_transfers, dependent: :nullify
  has_many :notifications, as: :notifiable, dependent: :destroy

  enum :status, { active: 0, inactive: 1 }
  translate_enum :status

  validates :origin_warehouse_id, :planned_date, presence: true
  validate :different_warehouses

  aasm column: "fulfillment_status" do
    state :pending, initial: true
    state :partially_fulfilled
    state :fulfilled

    event :mark_as_partially_fulfilled do
      transitions from: :pending, to: :partially_fulfilled
    end

    event :mark_as_fulfilled do
      transitions from: [ :pending, :partially_fulfilled ], to: :fulfilled
    end
  end

  accepts_nested_attributes_for :planned_stock_transfer_lines, allow_destroy: true, reject_if: :all_blank

  def different_warehouses
    if origin_warehouse && origin_warehouse == destination_warehouse
      errors.add(:destination_warehouse, "el almacén de envío y destino no pueden ser el mismo")
    end
  end

  def total_products
    planned_stock_transfer_lines.sum(:quantity)
  end

  def total_fulfilled_products
    planned_stock_transfer_lines.sum(:fulfilled_quantity)
  end

  def pending_stock_transfer_lines
    planned_stock_transfer_lines.select { |line| line.pending_quantity > 0 }
  end

  def update_fulfillment_status
    if planned_stock_transfer_lines.all? { |line| line.fulfilled? }
      mark_as_fulfilled! if may_mark_as_fulfilled?
    elsif planned_stock_transfer_lines.any? { |line| line.partially_fulfilled? }
      mark_as_partially_fulfilled! if may_mark_as_partially_fulfilled?
    end
  end
end
