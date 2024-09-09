module Services
  module Notifications
    class AlertHeaderIconService
      def initialize(notification)
        @notification = notification
      end

      def create
        Rails.logger.info("Creating alert header icon for notification: #{@notification.id}")
        # nothing to do here as this is handled by turbo broadcast in the model after_commit
      end
    end
  end
end
