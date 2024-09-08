module Services
  module Notifications
    module Strategies
      class PreorderStrategy < BaseStrategy
        def title
          "Tienda: #{location_name} - Venta #{@notifiable.order.custom_id} sin stock genera Preorden"
        end

        def body
          "Tienda: #{location_name} - Venta #{@notifiable.order.custom_id} sin stock genera Preorden #{object_identifier} por cantidad #{@notifiable.total_items} a cliente #{customer_name}"
        end

        def image_url
          @notifiable.products.first&.image_url
        end
      end
    end
  end
end
