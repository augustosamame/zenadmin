class SellerBiweeklySalesTarget < ApplicationRecord
  include TranslateEnum

  belongs_to :seller, class_name: "User"
  belongs_to :user
  belongs_to :location
  monetize :sales_target_cents, with_model_currency: :currency

  validates :year_month_period, presence: true, uniqueness: { scope: [ :seller_id, :location_id ] }
  validates :sales_target_cents, presence: true, numericality: { greater_or_equal_to: 0 }
  before_validation :set_target_commission

  enum :status, { pending: 0, completed: 1, inactive: 2 }
  translate_enum :status

  scope :for_seller, ->(seller_id) { where(seller_id: seller_id) }
  scope :for_period, ->(year_month_period) { where(year_month_period: year_month_period) }

  def self.generate_year_month_period(date)
    year = date.year
    month = date.month
    period = date.day <= 15 ? "I" : "II"
    "#{year}_#{month.to_s.rjust(2, '0')}_#{period}"
  end

  def self.current_year_month_period
    generate_year_month_period(Date.current)
  end

  def set_target_commission
    self.target_commission = 0 if self.target_commission.blank? # this accomodates sellers who dont earn commissions based on sales targets, only supervisors and store managers have this
  end

  def self.period_date_range(period)
    year = period.split("_")[0].to_i
    month = period.split("_")[1].to_i
    period_number = period.split("_")[2]

    date = Date.new(year, month, 1)

    if period_number == "I"
      # First period: 1st to 15th
      [ date.beginning_of_month, date.beginning_of_month + 14.days ]
    else
      # Second period: 16th to end of month
      [ date.beginning_of_month + 15.days, date.end_of_month ]
    end
  end

  def self.period_datetime_range(period)
    year = period.split("_")[0].to_i
    month = period.split("_")[1].to_i
    period_number = period.split("_")[2]

    date = Date.new(year, month, 1)

    if period_number == "I"
      # First period: 1st to 15th
      [
        date.beginning_of_month.beginning_of_day,
        (date.beginning_of_month + 14.days).end_of_day
      ]
    else
      # Second period: 16th to end of month
      [
        (date.beginning_of_month + 15.days).beginning_of_day,
        date.end_of_month.end_of_day
      ]
    end
  end

  def self.previous_year_month_period
    current_date = Date.current

    if current_date.day <= 15
      # If we're in the first period, go back to previous month's second period
      generate_year_month_period(current_date.prev_month.end_of_month)
    else
      # If we're in the second period, go back to current month's first period
      generate_year_month_period(current_date.beginning_of_month)
    end
  end
end
