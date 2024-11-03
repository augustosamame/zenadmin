module Services
  module Notifications
    module Strategies
      class MissingStockPeriodicInventoryStrategy < BaseStrategy
        # we override the notification type to use the correct one
        def notification_type
          "missing_stock_periodic_inventory"
        end

        def title
          "Diferencias en Inventario Físico: #{@notifiable.object_identifier}"
        end

        def body
          differences = @notifiable.differences
          total_items = differences.size

          "Se encontraron #{total_items} diferencias en el inventario que requieren confirmación. " \
          "Productos afectados: #{differences.map { |d| "#{d[:product].name} (#{d[:quantity]})" }.join(', ')}"
        end

        def image_url
          @notifiable.stock_transfers.first&.stock_transfer_lines&.first&.product&.smart_image(:thumb)
        end
      end
    end
  end
end
