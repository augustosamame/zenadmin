module Services
  module Inventory
    class PlannedStockTransferService
      attr_reader :planned_stock_transfer, :errors

      def initialize(planned_stock_transfer)
        @planned_stock_transfer = planned_stock_transfer
        @errors = []
      end

      def self.create_from_order(order)
        return if order.fast_stock_transfer_flag || order.order_items.empty?

        # Get the origin warehouse (location's warehouse)
        origin_warehouse = order.location&.warehouses&.first
        return if origin_warehouse.nil?

        ActiveRecord::Base.transaction do
          # Create a planned stock transfer
          planned_transfer = PlannedStockTransfer.new(
            user_id: order.user_id,
            origin_warehouse_id: origin_warehouse.id,
            destination_warehouse_id: nil,
            planned_date: Time.zone.now,
            comments: "Creado automáticamente desde la orden #{order.custom_id}",
            order_id: order.id
          )

          # Add lines for each product in the order
          order.order_items.each do |item|
            next if item.product.nil? || item.quantity <= 0

            planned_transfer.planned_stock_transfer_lines.build(
              product_id: item.product_id,
              quantity: item.quantity,
              fulfilled_quantity: 0
            )
          end

          # Save the planned stock transfer
          unless planned_transfer.save
            Rails.logger.error "Failed to create PlannedStockTransfer from Order #{order.id}: #{planned_transfer.errors.full_messages.join(", ")}"
            return nil
          end

          return planned_transfer
        end

        nil
      rescue StandardError => e
        Rails.logger.error "Error creating PlannedStockTransfer from Order #{order.id}: #{e.message}"
        nil
      end

      def create_stock_transfer(current_user)
        @errors = []

        # Check if there are pending lines to fulfill
        pending_lines = @planned_stock_transfer.pending_stock_transfer_lines
        if pending_lines.empty?
          @errors << "No hay líneas pendientes para transferir"
          return false
        end

        ActiveRecord::Base.transaction do
          # Create a new stock transfer
          stock_transfer = StockTransfer.new(
            user_id: current_user.id,
            origin_warehouse_id: @planned_stock_transfer.origin_warehouse_id,
            destination_warehouse_id: @planned_stock_transfer.destination_warehouse_id,
            transfer_date: Time.zone.now,
            comments: "Creado desde transferencia planificada #{@planned_stock_transfer.custom_id}",
            planned_stock_transfer_id: @planned_stock_transfer.id
          )

          # Add lines for each pending product
          pending_lines.each do |planned_line|
            pending_quantity = planned_line.pending_quantity
            next if pending_quantity <= 0

            stock_transfer.stock_transfer_lines.build(
              product_id: planned_line.product_id,
              quantity: pending_quantity
            )
          end

          # Save the stock transfer
          unless stock_transfer.save
            @errors << stock_transfer.errors.full_messages.join(", ")
            raise ActiveRecord::Rollback
          end

          # Update fulfilled quantities in the planned stock transfer lines
          stock_transfer.stock_transfer_lines.each do |transfer_line|
            planned_line = @planned_stock_transfer.planned_stock_transfer_lines.find_by(product_id: transfer_line.product_id)
            next unless planned_line

            planned_line.fulfilled_quantity += transfer_line.quantity
            unless planned_line.save
              @errors << planned_line.errors.full_messages.join(", ")
              raise ActiveRecord::Rollback
            end
          end

          # Update the fulfillment status of the planned stock transfer
          @planned_stock_transfer.update_fulfillment_status

          return true
        end

        false
      rescue StandardError => e
        @errors << "Error: #{e.message}"
        false
      end
    end
  end
end
