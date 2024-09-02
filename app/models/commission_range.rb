# app/models/commission_range.rb
class CommissionRange < ApplicationRecord
  belongs_to :user
  belongs_to :location

  # Validations
  validates :min_sales, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :max_sales, numericality: { greater_than: :min_sales }, allow_nil: true
  validates :commission_percentage, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Scope for easier querying of commission ranges within specific sales amounts
  scope :for_sales, ->(sales) { where("min_sales <= ? AND (max_sales IS NULL OR max_sales >= ?)", sales, sales) }

  # Method to find applicable commission for a given sales amount
  def self.find_commission_for_sales(sales, location)
    for_sales(sales).where(location_id: location.id).order(:min_sales).last
  end
end
