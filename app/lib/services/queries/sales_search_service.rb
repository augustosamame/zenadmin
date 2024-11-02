module Services
  module Queries
    class SalesSearchService
      def initialize(location: nil, seller: nil, date_range: nil, year_month_period: nil)
        @location = location
        @seller = seller
        @year_month_period = year_month_period
      end

      def sales_for_period_and_seller
        return [] unless @seller && @year_month_period
        start_date, end_date = date_range_for_period(@year_month_period)

        Commission.joins(order: :location)
          .where(user: @seller)
          .where(orders: { created_at: start_date.beginning_of_day..end_date.end_of_day })
          .where(orders: { status: :active, payment_status: :paid })
          .group(:location_id, "locations.name")
          .pluck("orders.location_id", "locations.name", "SUM(orders.total_price_cents)")
          .map do |location_id, location_name, total_cents|
            {
              location_id: location_id,
              location_name: location_name,
              seller_sales: total_cents
            }
          end
      end

      def sales_for_period_and_location(locations)
        return {} unless locations.any? && @year_month_period
        start_date, end_date = date_range_for_period(@year_month_period)

        Order.active.paid
          .where(location_id: locations)
          .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
          .group(:location_id)
          .sum(:total_price_cents)
      end

      def sales_on_month_for_location
        return 0 unless @location
        Order.active.paid
          .where(location: @location)
          .where(created_at: @date_range)
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
