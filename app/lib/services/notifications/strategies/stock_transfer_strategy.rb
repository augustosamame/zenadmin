module Services
  module Notifications
    module Strategies
      class StockTransferStrategy < BaseStrategy
        def title
          "Transferencia de Stock #{object_identifier} desde #{origin_warehouse_name} a #{destination_warehouse_name}"
        end

        def body
          "Transferencia de Stock #{object_identifier} desde #{origin_warehouse_name} a #{destination_warehouse_name}"
        end

        def image_url
          @notifiable.stock_transfer_lines&.first&.product&.smart_image(:thumb)
        end
      end
    end
  end
end
