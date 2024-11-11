class Requisition < ApplicationRecord
  audited_if_enabled

  include AASM
  include CustomNumberable
  include TranslateEnum

  belongs_to :user
  belongs_to :location
  belongs_to :warehouse
  has_many :requisition_lines, dependent: :destroy
  has_many :products, through: :requisition_lines
  has_many :notifications, as: :notifiable, dependent: :destroy

  enum :status, { active: 0, inactive: 1 }
  translate_enum :status
  enum :requisition_type, { automatic: 0, manual: 1 }
  translate_enum :requisition_type

  def self.stages
    {
      "req_draft" => "Borrador",
      "req_submitted" => "Enviado",
      "req_planned" => "Planificado",
      "req_pending" => "Pendiente",
      "req_fulfilled" => "Cumplido"
    }
  end

  accepts_nested_attributes_for :requisition_lines, allow_destroy: true

  validates :stage, inclusion: { in: stages.keys }
  validates :requisition_date, presence: true
  validates :custom_id, presence: true, uniqueness: true
  validates :warehouse_id, presence: true
  validates :location_id, presence: true
  validates :user_id, presence: true

  attr_accessor :submitted_alert_to_main_warehouse

  after_commit :send_submitted_alert_to_main_warehouse, if: :submitted_alert_to_main_warehouse

  aasm column: :stage do
    state :req_draft, initial: true # a requsition is created automatically each week for store_manager to confirm
    state :req_submitted # store_manager has confirmed the requisition and its sent to main warehouse
    state :req_planned # main warehouse has planned the requisition
    state :req_pending # main warehouse has not yet delivered all products (none or partial)
    state :req_fulfilled # all products in planned requisition have been delivered to the store

    event :submit do
      transitions from: :req_draft, to: :req_submitted, guard: :has_valid_quantities? do
        after do
          self.submitted_alert_to_main_warehouse = true
        end
      end
    end

    event :plan do
      transitions from: :req_submitted, to: :req_planned, guard: :has_planned_quantities? do
        after do
          create_associated_stock_transfer
        end
      end
    end

    event :fulfill do
      transitions from: :req_pending, to: :req_fulfilled
    end
  end

  def has_valid_quantities?
    requisition_lines.any? { |line| line.manual_quantity.to_i > 0 }
  end

  def has_planned_quantities?
    requisition_lines.any? { |line| line.planned_quantity.to_i > 0 }
  end

  def req_draft?
    stage == "req_draft"
  end

  def req_submitted?
    stage == "req_submitted"
  end

  def req_planned?
    stage == "req_planned"
  end

  def req_pending?
    stage == "req_pending"
  end

  def req_fulfilled?
    stage == "req_fulfilled"
  end

  def total_products
    requisition_lines.sum(:manual_quantity)
  end

  private

  def create_associated_stock_transfer
    origin_warehouse = self.warehouse
    destination_warehouse = self&.location&.warehouses&.first

    transfer = StockTransfer.create!(
      user: User.with_role("warehouse_manager")&.first,
      origin_warehouse: origin_warehouse,
      destination_warehouse: destination_warehouse,
      transfer_date: Time.current,
      comments: "Generado a partir del pedido ##{custom_id}",
      stage: "pending"
    )

    # Create stock transfer lines for each planned product
    requisition_lines.each do |req_line|
      next if req_line.planned_quantity.to_i <= 0

      transfer.stock_transfer_lines.create!(
        product: req_line.product,
        quantity: req_line.planned_quantity
      )
    end

    new_comment = "#{self.comments} - Generó trasferencia ##{transfer.custom_id}"
    self.update_columns(comments: new_comment) # TODO if stock_transfer is related to a pedido, update the pedido's line status and global status to pending once the transfer is confirmed, and to fulfilled once all products are delivered
  end

  def send_submitted_alert_to_main_warehouse
    Services::Notifications::CreateNotificationService.new(self).create
    Rails.logger.info "Requisition #{id} transitioned from draft to submitted state"
    self.submitted_alert_to_main_warehouse = false
  end
end
