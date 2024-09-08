module Services
  module Notifications
    module Strategies
      class OrderStrategy < BaseStrategy
        def title
          "Tienda: #{location_name} - Nueva Venta #{object_identifier}"
        end

        def body
          "Tienda: #{location_name} - Venta #{object_identifier} por #{formatted_total_price} a cliente #{customer_name}"
        end

        def image_url
          @notifiable.products.first&.smart_image(:thumb)
        end
      end
    end
  end
end
