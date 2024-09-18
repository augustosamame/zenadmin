module Services
  module Sales
    class OrderCommissionService
      def initialize(order)
        @order = order
      end

      def calculate_and_save_commissions(sellers_hash)
        # If any commissions for this order are already paid out, skip the calculation
        return if @order.commissions.joins(:commission_payout).exists?

        @order.commissions.destroy_all

        sellers = sellers_hash

        sellers.each do |seller_data|
          seller_comission_percentage = CommissionRange.find_commission_for_sales(Services::Queries::SalesSearchService.new(location: @order.location).sales_on_month_for_location, @order.location, @order.order_date)&.commission_percentage || 0

          seller_id = seller_data[:user_id] || seller_data[:id]
          percentage = seller_data[:percentage]
          seller = User.find(seller_id)
          sale_amount_cents = @order.total_price_cents * (percentage.to_f / 100)

          amount_cents = ((sale_amount_cents * (seller_comission_percentage / 100))/1.18)

          Commission.create!(
            user: seller,
            order: @order,
            sale_amount_cents: sale_amount_cents,
            amount_cents: amount_cents,
            percentage: percentage,
            status: @order.paid? ? :status_order_paid : :status_order_unpaid
          )
        end
      end

      # run this to calculate up to date commission amounts as the location commission rate may have changed if they reached a different range
      def self.recalculate_commissions
        Commission.where.not(status: :status_paid_out).includes(order: :location).each do |commission|
          seller_comission_percentage = CommissionRange.find_commission_for_sales(Services::Queries::SalesSearchService.new(location: commission.order.location).sales_on_month_for_location, commission.order.location, commission.order.order_date)&.commission_percentage || 0
          sale_amount_cents = commission.order.total_price_cents * (commission.percentage.to_f / 100)
          amount_cents = ((sale_amount_cents * (seller_comission_percentage / 100))/1.18)
          commission.update(amount_cents: amount_cents)
        end
      end
    end
  end
end
