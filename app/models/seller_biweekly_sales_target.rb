class SellerBiweeklySalesTarget < ApplicationRecord
  include TranslateEnum

  belongs_to :seller, class_name: "User"
  belongs_to :user

  monetize :sales_target_cents, with_model_currency: :currency

  validates :year_month_period, presence: true, uniqueness: { scope: :seller_id }
  validates :sales_target_cents, presence: true, numericality: { greater_or_equal_to: 0 }
  validates :target_commission, presence: true, numericality: { greater_or_equal_to: 0, less_than_or_equal_to: 100 }

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
end
