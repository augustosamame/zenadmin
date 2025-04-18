class NotificationSetting < ApplicationRecord
  TRIGGER_TYPES = %w[order preorder stock_transfer stock_transfer_partial_receipt missing_stock_periodic_inventory requisition].freeze

  validates :trigger_type, presence: true, uniqueness: true, inclusion: { in: TRIGGER_TYPES }
  validates :media, presence: true

  # Returns the notification media for a specific trigger type
  def self.for(trigger_type)
    find_by(trigger_type: trigger_type)
  end
end
