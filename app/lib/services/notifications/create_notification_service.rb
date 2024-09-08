module Services
  module Notifications
    class CreateNotificationService
      def initialize(notifiable)
        @notifiable = notifiable
        @strategy = notification_strategy_for(notifiable)
      end

      def create
        notification_setting = NotificationSetting.for(@strategy.notification_type)
        notification_setting.each do |medium, enabled|
          create_notification(medium) if enabled
        end
      end

      private

      def create_notification(medium)
        Notification.create!(
          notifiable: @notifiable,
          medium: medium,
          message_title: @strategy.title,
          message_body: @strategy.body,
          message_image: @strategy.image_url
        )
      end

      def notification_strategy_for(notifiable)
        strategy_class = "Services::Notifications::Strategies::#{notifiable.class.name}Strategy"
        strategy_class.constantize.new(notifiable)
      rescue NameError
        Services::Notifications::Strategies::DefaultStrategy.new(notifiable)
      end
    end
  end
end
