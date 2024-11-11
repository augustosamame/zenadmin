module Services
  module Notifications
    module Strategies
      class RequisitionStrategy < BaseStrategy
        def title
          "#{@notifiable&.location&.name} - Nuevo Pedido #{object_identifier}"
        end

        def body
          "Nuevo Pedido #{object_identifier} por #{@notifiable&.total_products} de la tienda: #{@notifiable&.location&.name}"
        end

        def image_url
          @notifiable.requisition_lines.first&.product&.smart_image(:thumb)
        end
      end
    end
  end
end
