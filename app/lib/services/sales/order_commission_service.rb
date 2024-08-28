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
          seller_id = seller_data[:user_id] || seller_data[:id]
          percentage = seller_data[:percentage]
          seller = User.find(seller_id)
          amount = (@order.total_price_cents * (percentage.to_f / 100) * (@order.location.seller_comission_percentage / 100)).round

          Commission.create!(
            user: seller,
            order: @order,
            amount_cents: amount,
            percentage: percentage,
            status: @order.paid? ? :status_order_paid : :status_order_unpaid
          )
        end
      end
    end
    
  end
end
