module Services
  module Queries
    class SalesSearchService
      def initialize(location: nil, seller: nil, date_range: nil)
        @location = location
        @seller = seller
        @date_range = date_range || (Time.now.beginning_of_month..Time.now.end_of_month) # Default to current month
      end

      def sales_on_month_for_location
        @sales_on_month_for_location = Order.where(location: @location, created_at: @date_range).where.not(status: :pending).sum(:total_price_cents) / 100
      end
    end
  end
end
