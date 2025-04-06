class CashOutflow < ApplicationRecord
  include CustomNumberable

  belongs_to :cashier_shift
  belongs_to :paid_to, class_name: "User", optional: true # User who received the cash outflow
  has_one :cashier_transaction, as: :transactable, dependent: :destroy
  has_many :media, as: :attachable, dependent: :destroy

  # Custom attribute to store the target cashier ID for cashier transfers
  attr_accessor :target_cashier_id

  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }

  # Skip validation entirely for cashier transfers
  validates :paid_to, presence: true, unless: :skip_paid_to_validation?

  monetize :amount_cents, with_model_currency: :currency

  # Check if this is a cashier-to-cashier transfer
  def cashier_transfer?
    $global_settings[:feature_flag_bank_cashiers_active].present? && 
      (target_cashier_id.to_s.start_with?("cashier_") || paid_to_id.to_s.start_with?("cashier_"))
  end

  # Method to determine if paid_to validation should be skipped
  def skip_paid_to_validation?
    # Check if the feature flag is enabled
    feature_enabled = $global_settings[:feature_flag_bank_cashiers_active].present?
    
    # Check if this is a cashier transfer using either target_cashier_id or paid_to_id
    is_cashier_transfer = target_cashier_id.to_s.start_with?("cashier_") || paid_to_id.to_s.start_with?("cashier_")

    # Log values for debugging
    Rails.logger.debug("CashOutflow#skip_paid_to_validation? - feature_enabled: #{feature_enabled}, paid_to_id: #{paid_to_id}, target_cashier_id: #{target_cashier_id}, is_cashier_transfer: #{is_cashier_transfer}")

    # Skip validation if both conditions are true
    feature_enabled && is_cashier_transfer
  end
end
