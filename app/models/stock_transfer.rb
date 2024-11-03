# app/models/stock_transfer.rb
class StockTransfer < ApplicationRecord
  include AASM
  include CustomNumberable
  include TranslateEnum

  belongs_to :user
  belongs_to :origin_warehouse, class_name: "Warehouse", optional: true
  belongs_to :destination_warehouse, class_name: "Warehouse", optional: true
  belongs_to :periodic_inventory, class_name: "PeriodicInventory", optional: true
  has_many :stock_transfer_lines, dependent: :destroy
  has_many :products, through: :stock_transfer_lines

  has_many :notifications, as: :notifiable, dependent: :destroy


  enum :status, { active: 0, inactive: 1 }
  translate_enum :status
  enum :adjustment_type, { devolucion: 0, perdida_o_robo: 1, rotura: 2, venta_incorrecta: 3, otros: 4 }
  translate_enum :adjustment_type

  validates :origin_warehouse_id, presence: true, if: :is_adjustment?
  validates :destination_warehouse_id, presence: true, unless: :is_adjustment?

  aasm column: "stage" do
    state :pending, initial: true
    state :in_transit
    state :complete

    event :start_transfer do
      transitions from: :pending, to: :in_transit, guard: :in_transit_step_enabled?, after: :process_in_transit
      transitions from: :pending, to: :complete, unless: :in_transit_step_enabled?, after: :process_complete
    end

    event :finish_transfer do
      transitions from: [ :in_transit, :pending ], to: :complete, after: :process_complete
    end
  end

  accepts_nested_attributes_for :stock_transfer_lines, allow_destroy: true

  validate :different_warehouses

  before_destroy :check_if_can_be_destroyed

  def different_warehouses
    if origin_warehouse && origin_warehouse == destination_warehouse
      errors.add(:destination_warehouse, "el almacén de envío y destino no pueden ser el mismo")
    end
  end

  def total_products
    stock_transfer_lines.sum(:quantity)
  end

  def check_if_can_be_destroyed
    if complete?
      errors.add(:base, "No se puede eliminar una transferencia de Stock completada")
      throw :abort
    end
    if in_transit?
      errors.add(:base, "No se puede eliminar una transferencia de Stock en tránsito")
      throw :abort
    end
  end

  private

  def process_in_transit
    Services::Inventory::StockTransferService.new(self).update_origin_warehouse_inventory
  end

  def process_complete
    Services::Inventory::StockTransferService.new(self).update_destination_warehouse_inventory
  end

  def in_transit_step_enabled?
    $global_settings[:stock_transfers_have_in_transit_step]
  end
end
