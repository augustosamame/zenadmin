module Services
  module Notifications
    module Strategies
      class PartialStockTransferStrategy < BaseStrategy
        # we override the notification type to use the correct one
        def notification_type
          "stock_transfer_partial_receipt"
        end
        def title
          "Transferencia de Stock Incompleta #{object_identifier} desde #{origin_warehouse_name} a #{destination_warehouse_name}"
        end

        def body
          missing_products = @notifiable.stock_transfer_lines
            .select { |line| line.received_quantity != line.quantity }
            .map do |line|
              missing_quantity = line.quantity - line.received_quantity
              "#{line.product.name} (#{missing_quantity})"
            end

          "Productos faltantes: #{missing_products.join(', ')}"
        end

        def image_url
          @notifiable.stock_transfer_lines&.first&.product&.smart_image(:thumb)
        end
      end
    end
  end
end
