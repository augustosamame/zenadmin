module Services
  module Sales
    class LoyaltyTierService
      def initialize(user)
        @user = user
      end

      def self.update_all_users_loyalty_tiers
        User.find_each do |user|
          new(user).update_loyalty_tier # necessary to use new(user) because @user will be used in the method
        end
      end

      def update_loyalty_tier
        qualifying_tier = find_qualifying_tier
        if qualifying_tier.present?
          if qualifying_tier.id != @user.loyalty_tier_id
            @user.update!(loyalty_tier: qualifying_tier, reached_loyalty_tier_at: Time.current)
            assign_perks
          end
        else
          @user.update!(loyalty_tier: nil, reached_loyalty_tier_at: nil)
          @user.user_free_products.destroy_all
        end
      end

      def loyalty_info
        current_time = Time.current
        tier_reached_at = @user.reached_loyalty_tier_at
        all_tiers = LoyaltyTier.order(requirements_total_amount: :asc, requirements_orders_count: :asc)

        puts "tier_reached_at: #{tier_reached_at}"
        if tier_reached_at.present? && (current_time.to_date - tier_reached_at.to_date) >= 1
          puts "tier_reached_at is present and the difference in days is >= 1"
          tier_active = true
        else
          puts "tier_reached_at is present and the difference in days is < 1"
          tier_active = false
        end
        current_tier = @user.loyalty_tier

        next_tier = LoyaltyTier.where("requirements_orders_count > ? OR requirements_total_amount > ?", current_tier&.requirements_orders_count.to_i, current_tier&.requirements_total_amount.to_f)
                         .order(requirements_total_amount: :asc, requirements_orders_count: :asc).first

        {
          current_tier_id: current_tier&.id,
          current_tier_name: current_tier&.name || "Sin Rango Actual",
          progress_to_next_tier: progress_to_next_tier(next_tier),
          discount_percentage: current_tier&.discount_percentage.present? ? current_tier&.discount_percentage * 100 : 0,
          free_product: free_product_info(current_tier),
          days_since_tier_reached: days_since_tier_reached(tier_reached_at),
          tier_active: tier_active
        }
      end

      def update_free_product_availability(order)
        order.order_items.each do |item|
          if item.is_loyalty_free
            product = item.product
            tier = @user.loyalty_tier
            user_free_product = @user.user_free_products.find_by(product: product, loyalty_tier: tier)
            if user_free_product.present?
              user_free_product.update(status: :claimed, claimed_at: Time.current)
            end
          end
        end
      end

      private

      def progress_to_next_tier(next_tier)
        return "No hay un rango superior de loyalty" unless next_tier

        orders_count = orders_in_last_12_months.count
        total_amount = orders_in_last_12_months.sum(:total_price_cents) / 100.0

        progress = []
        progress << "van #{orders_count}/#{next_tier.requirements_orders_count} compras" if next_tier.requirements_orders_count.present?
        progress << "y S/ #{total_amount.round(2)} de S/ #{next_tier.requirements_total_amount}" if next_tier.requirements_total_amount.present?

        progress.join(" ")
      end

      def free_product_info(tier)
        return nil unless tier&.free_product_id

        product = Product.find_by(id: tier.free_product_id)
        return nil unless product

        if free_product_available?(product, tier)
          { id: product.id, name: product.name, custom_id: product.custom_id }
        else
          nil
        end
      end

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
          if free_product && !free_product_assigned?(free_product, @user.loyalty_tier)
            @user.user_free_products.create(product: free_product, loyalty_tier: @user.loyalty_tier, status: :available)
          end
        end

        # Note: Discount percentage is applied dynamically when creating/updating orders
      end

      def free_product_assigned?(product, tier)
        @user.user_free_products.find_by(product: product, loyalty_tier: tier).present?
      end

      def free_product_available?(product, tier)
        return false if product.nil?
        last_free_product = @user.user_free_products.available.find_by(product: product, loyalty_tier: tier)
        last_free_product.present?
      end

      def days_since_tier_reached(tier_reached_at)
        if tier_reached_at.present?
          (Time.current.to_date - tier_reached_at.to_date).to_i
        else
          nil
        end
      end
    end
  end
end
