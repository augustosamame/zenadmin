module Services
  module Sales
    class LoyaltyTierService
      def initialize(user)
        @user = user
      end

      def update_loyalty_tier
        qualifying_tier = find_qualifying_tier
        if qualifying_tier != @user.loyalty_tier
          @user.update!(loyalty_tier: qualifying_tier)
          assign_perks if qualifying_tier
        end
      end

      private

      def find_qualifying_tier
        LoyaltyTier.where(
          "requirements_orders_count <= :order_count OR requirements_total_amount <= :total_amount",
          order_count: orders_in_last_12_months.count,
          total_amount: orders_in_last_12_months.sum(:total_price_cents) / 100
        ).order(requirements_total_amount: :desc, requirements_orders_count: :desc).first
      end

      def amount_or_count_of_orders_for_next_tier(tier)
        if tier.requirements_orders_count.present?
          orders_in_last_12_months.count >= tier.requirements_orders_count
        else
          orders_in_last_12_months.sum(:total_price) >= tier.requirements_total_amount
        end
      end

      def orders_in_last_12_months
        @user.orders.where("order_date >= ?", 12.months.ago)
      end

      def assign_perks
        return unless @user.loyalty_tier

        if @user.loyalty_tier.free_product_id
          # Grant free product if available for the tier and not received in the last year
          free_product = Product.find_by(id: @user.loyalty_tier.free_product_id)
          if free_product && free_product_available?(free_product, @user.loyalty_tier)
            @user.user_free_products.create(product: free_product, loyalty_tier: @user.loyalty_tier, status: :available)
          end
        end

        # Note: Discount percentage is applied dynamically when creating/updating orders
      end

      def free_product_available?(product, loyalty_tier)
        return false if product.nil?
        last_free_product = @user.user_free_products.available.find_by(product: product, loyalty_tier: loyalty_tier)
        last_free_product.blank?
      end
    end
  end
end
