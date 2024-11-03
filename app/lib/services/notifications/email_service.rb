module Services
  module Notifications
    class EmailService
      def initialize(notification)
        @notification = notification
      end

      def create
        Rails.logger.info("Creating email for notification: #{@notification.id}")
        case @notification.notifiable_type
        when "Order"
          # AdminMailer.with(notification: @notification).order.deliver_now
        when "StockTransfer"
          AdminMailer.with(notification: @notification).partial_stock_transfer.deliver_later
        when "PeriodicInventory"
          AdminMailer.with(notification: @notification).missing_stock_periodic_inventory.deliver_later
        end
      end
    end
  end
end
