module Services
  module Notifications
    module Strategies
      class BaseStrategy
        include CurrencyFormattable

        def initialize(notifiable)
          @notifiable = notifiable
        end

        def notification_type
          @notifiable.class.name.underscore.to_sym
        end

        def title
          raise NotImplementedError
        end

        def body
          raise NotImplementedError
        end

        def image_url
          nil
        end

        protected

        def location_name
          @notifiable.location.name
        end

        def object_identifier
          "##{@notifiable.custom_id}"
        end

        def formatted_total_price
          format_currency(@notifiable.total_price)
        end

        def customer_name
          @notifiable.customer.name
        end
      end
    end
  end
end
