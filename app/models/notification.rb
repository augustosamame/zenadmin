class Notification < ApplicationRecord
  belongs_to :notifiable, polymorphic: true

  # broadcasts_refreshes

  enum :medium, { notification_feed: 0, alert_header_icon: 1, dashboard: 2, email: 3, sms: 4, whatsapp: 5, only_action_cable: 6 }
  enum :status, { unread: 0, read: 1, clicked: 2, opened: 3 }
  enum :severity, { info: 0, warning: 1, critical: 2 }

  after_commit :deliver_notification, on: :create

  def deliver_notification
    case medium
    when "notification_feed"
      Services::Notifications::NotificationFeedService.new(self).create
      broadcast_refresh_to "notifications" # , target: "notification_feed"
    when "alert_header_icon"
      Services::Notifications::AlertHeaderIconService.new(self).create
    when "dashboard"
      Services::Notifications::DashboardAlertService.new(self).create
    when "email"
      Services::Notifications::EmailService.new(self).create
    when "sms"
      Services::Notifications::SmsService.new(self).create
    when "whatsapp"
      Services::Notifications::WhatsappService.new(self).create
    when "only_action_cable"
      Services::Notifications::ActionCableService.new(self).create
    end
  end

  # Mark notification as read (for dashboard alerts)
  def mark_as_read
    update(status: :read, read_at: Time.current)
  end

  def mark_as_clicked
    update(status: :clicked, clicked_at: Time.current)
  end

  def mark_as_opened
    update(status: :opened, opened_at: Time.current)
  end
end
