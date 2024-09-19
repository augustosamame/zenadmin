module Services
  module Notifications
    class NotificationFeedService
      def initialize(notification)
        @notification = notification
      end

      def create
        Rails.logger.info("Creating notification feed for notification: #{@notification.id}")
        # nothing to do here as this is handled by turbo broadcast in the model after_commit
      end
    end
  end
end