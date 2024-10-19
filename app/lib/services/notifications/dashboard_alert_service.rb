module Services
  module Notifications
    class DashboardAlertService
      def initialize(notification)
        @notification = notification
      end

      def create
        Rails.logger.info("Creating dashboard alert for notification: #{@notification.id}")
      end
    end
  end
end
