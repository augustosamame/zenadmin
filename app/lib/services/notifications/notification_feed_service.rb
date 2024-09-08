module Services
  module Notifications
    class NotificationFeedService
      def initialize(notification)
        @notification = notification
      end

      def create
        Rails.logger.info("Creating notification feed for notification: #{@notification.id}")
      end
    end
  end
end
