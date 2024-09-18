# app/models/commission_range.rb
class CommissionRange < ApplicationRecord
  belongs_to :user
  belongs_to :location

  # Validations
  validates :min_sales, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :max_sales, numericality: { greater_than: :min_sales }, allow_nil: true
  validates :commission_percentage, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :year_month_period, presence: true

  # Scope for easier querying of commission ranges within specific sales amounts
  scope :for_sales, ->(sales) { where("min_sales <= ? AND (max_sales IS NULL OR max_sales >= ?)", sales, sales) }
  scope :for_period, ->(year_month_period) { where(year_month_period: year_month_period) }

  # Method to find applicable commission for a given sales amount
  def self.find_commission_for_sales(sales, location, date)
    for_sales(sales).where(location_id: location.id, year_month_period: generate_year_month_period(date)).order(:min_sales).last
  end

  def self.generate_year_month_period(date)
    year = date.year
    month = date.month
    period = date.day <= 15 ? "I" : "II"
    "#{year}_#{month.to_s.rjust(2, '0')}_#{period}"
  end

  def self.current_year_month_period
    generate_year_month_period(Date.current)
  end
end
