module Services
  module Notifications
    class EmailService
      def initialize(notification)
        @notification = notification
      end

      def create
        Rails.logger.info("Creating email for notification: #{@notification.id}")
        AdminMailer.with(notification: @notification).partial_stock_transfer.deliver_now
      end
    end
  end
end
