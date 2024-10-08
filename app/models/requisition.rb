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

  enum :stage, { req_new: 0, req_pending: 1, req_fulfilled: 2 }
  translate_enum :stage
  enum :status, { active: 0, inactive: 1 }
  translate_enum :status
  enum :requisition_type, { automatic: 0, manual: 1 }
  translate_enum :requisition_type

  accepts_nested_attributes_for :requisition_lines, allow_destroy: true

  validates :requisition_date, presence: true
  validates :custom_id, presence: true, uniqueness: true
  validates :warehouse_id, presence: true
  validates :location_id, presence: true
  validates :user_id, presence: true

  attr_accessor :pending_alert_to_main_warehouse

  after_commit :send_pending_alert_to_main_warehouse, if: :pending_alert_to_main_warehouse

  aasm column: "stage", enum: true do
    state :req_new, initial: true
    state :req_pending
    state :req_fulfilled

    event :submit do
      transitions from: :req_new, to: :req_pending do
        after do
          self.pending_alert_to_main_warehouse = true
        end
      end
    end

    event :fulfill do
      transitions from: :req_pending, to: :req_fulfilled
    end
  end

  def total_products
    requisition_lines.sum(:manual_quantity)
  end

  private

  def send_pending_alert_to_main_warehouse
    # NotificationService.notify_pending_requisition(self)
    Rails.logger.info "Requisition #{id} transitioned from new to pending state"
    self.pending_alert_to_main_warehouse = false
  end
end
