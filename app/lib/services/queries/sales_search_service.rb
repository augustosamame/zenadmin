module Services
  module Queries
    class SalesSearchService
      def initialize(location: nil, seller: nil, date_range: nil, year_month_period: nil)
        @location = location
        @seller = seller
        @date_range = date_range || (Time.current.beginning_of_month..Time.current.end_of_month) # Default to current month
        @year_month_period = year_month_period
      end

      def sales_on_month_for_location
        @sales_on_month_for_location = Order.where(location: @location, created_at: @date_range).where.not(status: :pending).sum(:total_price_cents) / 100
      end

      def sales_for_period_and_seller
        return 0 unless @seller && @year_month_period
        start_date, end_date = date_range_for_period(@year_month_period)
        Order.active.paid.where(seller: @seller, created_at: start_date.beginning_of_day..end_date.end_of_day)
             .sum(:total_price_cents)
      end

      def sales_for_period_and_location(location = nil)
        location ||= @location
        return 0 unless location && @year_month_period
        start_date, end_date = date_range_for_period(@year_month_period)
        Order.active.paid.where(location: location, created_at: start_date.beginning_of_day..end_date.end_of_day)
             .sum(:total_price_cents)
      end

      private

      def date_range_for_period(year_month_period)
        year, month, period = year_month_period.split("_")
        start_date = Date.new(year.to_i, month.to_i, period == "I" ? 1 : 16)
        end_date = period == "I" ? start_date.end_of_month.change(day: 15) : start_date.end_of_month
        [ start_date, end_date ]
      end
    end
  end
end
