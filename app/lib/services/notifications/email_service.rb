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
          #AdminMailer.with(notification: @notification).order.deliver_now
        when "StockTransfer"
          AdminMailer.with(notification: @notification).partial_stock_transfer.deliver_now
        end
      end
    end
  end
end
