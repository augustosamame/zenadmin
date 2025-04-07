# app/models/stock_transfer.rb
class StockTransfer < ApplicationRecord
  include AASM
  include CustomNumberable
  include TranslateEnum

  belongs_to :user
  belongs_to :origin_warehouse, class_name: "Warehouse", optional: true
  belongs_to :destination_warehouse, class_name: "Warehouse", optional: true
  belongs_to :periodic_inventory, class_name: "PeriodicInventory", optional: true
  belongs_to :planned_stock_transfer, optional: true
  belongs_to :transportista, optional: true
  has_many :guias, dependent: :nullify

  attr_accessor :current_user_for_destroy, :cached_lines, :create_guia

  validates :transportista_id, presence: true, if: -> { create_guia == "1" || create_guia == true }

  def cache_lines
    Rails.logger.info "Starting to cache lines for StockTransfer ##{id}"
    lines = stock_transfer_lines.includes(:product).to_a
    Rails.logger.info "Found #{lines.size} lines to cache"
    lines.each do |line|
      Rails.logger.info "Caching line: product_id=#{line.product_id}, quantity=#{line.quantity}"
    end
    self.cached_lines = lines
    Rails.logger.info "Finished caching #{cached_lines.size} lines"
  rescue => e
    Rails.logger.error "Error caching lines: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  has_many :stock_transfer_lines, dependent: :destroy
  has_many :products, through: :stock_transfer_lines
  has_many :in_transit_stocks, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy

  after_save :set_date_guia

  before_destroy :check_if_can_be_destroyed, prepend: true
  before_destroy :cache_lines, prepend: true
  before_destroy :revert_stocks

  enum :status, { active: 0, inactive: 1 }
  translate_enum :status
  enum :adjustment_type, { devolucion: 0, perdida_o_robo: 1, rotura: 2, venta_incorrecta: 3, otros: 4 }
  translate_enum :adjustment_type

  validates :origin_warehouse_id, presence: true, if: :is_adjustment?
  validates :destination_warehouse_id, presence: true, unless: :is_adjustment?
  validates :stage, presence: true

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

  def different_warehouses
    if origin_warehouse && origin_warehouse == destination_warehouse
      errors.add(:destination_warehouse, "el almacén de envío y destino no pueden ser el mismo")
    end
  end

  def total_products
    stock_transfer_lines.sum(:quantity)
  end

  def check_if_can_be_destroyed
    unless current_user_for_destroy&.any_admin?
      if aasm.current_state == :complete
        errors.add(:base, "No se puede eliminar una transferencia de Stock completada")
        throw :abort
      end
      if aasm.current_state == :in_transit
        errors.add(:base, "No se puede eliminar una transferencia de Stock en tránsito")
        throw :abort
      end
    end
  end

  def set_date_guia
    self.date_guia = self.transfer_date
  end

  def revert_stocks
    Rails.logger.info "Starting revert_stocks for StockTransfer ##{id}"
    Rails.logger.info "Stage: #{stage}, Current State: #{aasm.current_state}"
    Rails.logger.info "Number of cached lines: #{cached_lines&.size}"

    unless cached_lines.present?
      Rails.logger.error "No cached lines found for StockTransfer ##{id}, cannot revert stocks"
      return
    end

    case aasm.current_state
    when :in_transit
      Rails.logger.info "Reverting in-transit stocks"
      revert_in_transit_stocks
    when :complete
      Rails.logger.info "Reverting complete stocks"
      revert_complete_stocks
    else
      Rails.logger.info "No stock reversion needed for stage: #{stage}"
    end
  rescue => e
    Rails.logger.error "Error in revert_stocks: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  def revert_in_transit_stocks
    ActiveRecord::Base.transaction do
      cached_lines.each do |line|
        Rails.logger.info "Reverting in-transit line for product #{line.product_id} with quantity #{line.quantity}"

        warehouse_inventory = WarehouseInventory.find_or_initialize_by(
          warehouse_id: origin_warehouse_id,
          product_id: line.product_id
        )
        warehouse_inventory.stock ||= 0
        warehouse_inventory.stock += line.quantity
        warehouse_inventory.save!
        Rails.logger.info "Updated origin warehouse stock to #{warehouse_inventory.stock}"
      end
    end
  end

  def revert_complete_stocks
    ActiveRecord::Base.transaction do
      cached_lines.each do |line|
        Rails.logger.info "Reverting complete line for product #{line.product_id} with quantity #{line.quantity}"

        # Add back to origin
        origin_inventory = WarehouseInventory.find_or_initialize_by(
          warehouse_id: origin_warehouse_id,
          product_id: line.product_id
        )
        origin_inventory.stock ||= 0
        origin_inventory.stock += line.quantity
        origin_inventory.save!
        Rails.logger.info "Updated origin warehouse stock to #{origin_inventory.stock}"

        # Remove from destination
        destination_inventory = WarehouseInventory.find_or_initialize_by(
          warehouse_id: destination_warehouse_id,
          product_id: line.product_id
        )
        destination_inventory.stock ||= 0
        quantity_to_subtract = line.received_quantity || line.quantity
        destination_inventory.stock -= quantity_to_subtract
        destination_inventory.save!
        Rails.logger.info "Updated destination warehouse stock to #{destination_inventory.stock}"
      end
    end
  end

  def process_in_transit
    Services::Inventory::StockTransferService.new(self).update_origin_warehouse_inventory
  end

  def process_complete
    if is_adjustment?
      Services::Inventory::StockTransferService.new(self).update_adjustment_inventory
    else
      Services::Inventory::StockTransferService.new(self).update_destination_warehouse_inventory
    end
  end

  def in_transit_step_enabled?
    $global_settings[:stock_transfers_have_in_transit_step]
  end
end
