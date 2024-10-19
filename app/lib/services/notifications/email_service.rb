module Services
  module Notifications
    class EmailService
      def initialize(notification)
        @notification = notification
      end

      def create
        Rails.logger.info("Creating email for notification: #{@notification.id}")
      end
    end
  end
end
