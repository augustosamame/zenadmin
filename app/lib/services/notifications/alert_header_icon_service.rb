module Services
  module Notifications
    class AlertHeaderIconService
      def initialize(notification)
        @notification = notification
      end

      def create
        Rails.logger.info("Creating alert header icon for notification: #{@notification.id}")
      end
    end
  end
end
