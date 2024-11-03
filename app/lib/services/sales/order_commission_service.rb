module Services
  module Sales
    class OrderCommissionService
      def initialize(order)
        @order = order
      end

      def calculate_and_save_commissions(sellers_array)
        return false if sellers_array.blank?
        return false if @order.commissions.joins(:commission_payout).exists?

        ActiveRecord::Base.transaction do
          @order.commissions.destroy_all

          sellers_array.each do |seller_data|
            next if seller_data[:percentage].to_f.zero? || seller_data[:user_id].blank?

            seller_commission_percentage = CommissionRange.find_commission_for_sales(
              Services::Queries::SalesSearchService.new(location: @order.location).sales_on_month_for_location,
              @order.location,
              @order.order_date
            )&.commission_percentage || 0

            seller = User.find(seller_data[:user_id])
            percentage = seller_data[:percentage].to_f

            sale_amount_cents = (@order.total_price_cents * (percentage / 100.0)).round
            amount_cents = ((sale_amount_cents * (seller_commission_percentage / 100.0)) / 1.18).round

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

        true
      rescue => e
        Rails.logger.error "Error calculating commissions: #{e.message}"
        false
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

      def recalculate_commissions
        @order.commissions.where.not(status: :status_paid_out).each do |commission|
          seller_commission_percentage = CommissionRange.find_commission_for_sales(
            Services::Queries::SalesSearchService.new(location: @order.location).sales_on_month_for_location,
            @order.location,
            @order.order_date
          )&.commission_percentage || 0

          # Calculate the new sale_amount_cents based on the updated percentage
          sale_amount_cents = (@order.total_price_cents * commission.percentage / 100).round

          # Calculate the new amount_cents
          amount_cents = ((sale_amount_cents * seller_commission_percentage / 100) / 1.18).round

          # Update both sale_amount_cents and amount_cents
          commission.update(sale_amount_cents: sale_amount_cents, amount_cents: amount_cents)
        end
      end
    end
  end
end
