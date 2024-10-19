module Services
  module Notifications
    class CreateNotificationService
      def initialize(notifiable, options = {})
        @notifiable = notifiable
        @strategy = notification_strategy_for(notifiable, options[:custom_strategy])
        @options = options
      end

      def create
        notification_setting = NotificationSetting.for(@strategy.notification_type)
        notification_setting.media.each do |medium|
          if medium[1]
            create_notification(medium)
          end
        end
      end

      private

      def create_notification(medium)
        Notification.create!(
          notifiable: @notifiable,
          medium: medium[0],
          message_title: @strategy.title,
          message_body: @strategy.body,
          message_image: @strategy.image_url
        )
      end

      def notification_strategy_for(notifiable, custom_strategy = nil)
        if custom_strategy
          strategy_class = "Services::Notifications::Strategies::#{custom_strategy}Strategy"
        else
          strategy_class = "Services::Notifications::Strategies::#{notifiable.class.name}Strategy"
        end
        strategy_class.constantize.new(notifiable)
      rescue NameError
        raise "Strategy for #{strategy_class} not found"
        # Services::Notifications::Strategies::DefaultStrategy.new(notifiable)
      end
    end
  end
end
