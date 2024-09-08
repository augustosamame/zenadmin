module Services
  module Notifications
    module Strategies
      class BaseStrategy
        include ActionView::Helpers::NumberHelper

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
          number_to_currency(@notifiable.total_price, unit: @notifiable.currency, format: "%u %n")
        end

        def customer_name
          @notifiable.user.name
        end
      end
    end
  end
end
