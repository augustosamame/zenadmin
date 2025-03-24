class AdminMailer < ApplicationMailer
  layout "admin_mailer"

  PRODUCTION_EXTRA_EMAILS_JARDIN_DEL_ZEN = [
    "asistentecontable@aromaterapia.com.pe",
    "asistenteadministrativo@aromaterapia.com.pe"
  ].freeze

  PRODUCTION_EXTRA_EMAILS_SERCAM = [
    "fserna@sercam.com.pe"
  ].freeze

  case ENV["CURRENT_ORGANIZATION"]
  when "jardindelzen"
    PRODUCTION_EXTRA_EMAILS = PRODUCTION_EXTRA_EMAILS_JARDIN_DEL_ZEN
  when "sercam"
    PRODUCTION_EXTRA_EMAILS = PRODUCTION_EXTRA_EMAILS_SERCAM
  when "oec"
    PRODUCTION_EXTRA_EMAILS = PRODUCTION_EXTRA_EMAILS_SERCAM
  else
    PRODUCTION_EXTRA_EMAILS = []
  end

  DEVELOPMENT_EMAILS = [ "augusto@devtechperu.com" ].freeze
  CC_EMAIL = "augusto@devtechperu.com".freeze

  def partial_stock_transfer
    @notification = params[:notification]
    @stock_transfer = @notification.notifiable

    mail(
      subject: @notification.message_title,
      to: notifiable_emails,
      cc: CC_EMAIL
    )
  end

  def missing_stock_periodic_inventory
    @notification = params[:notification]
    @periodic_inventory = @notification.notifiable

    mail(
      subject: @notification.message_title,
      to: notifiable_emails,
      cc: CC_EMAIL
    )
  end

  def requisition
    @notification = params[:notification]
    @requisition = @notification.notifiable
    if ENV["RAILS_ENV"] == "production"
      @requisition_notifiable_emails = PRODUCTION_EXTRA_EMAILS
    else
      @requisition_notifiable_emails = DEVELOPMENT_EMAILS
    end

    mail(
      subject: @notification.message_title,
      to: @requisition_notifiable_emails,
      cc: CC_EMAIL
    )
  end

  private

  def notifiable_emails
    if ENV["RAILS_ENV"] == "production"
      super_admin_users = User.with_role("super_admin")
      (PRODUCTION_EXTRA_EMAILS + super_admin_users.pluck(:email)).uniq
    else
      DEVELOPMENT_EMAILS
    end
  rescue => e
    Rails.logger.error "Error getting notifiable emails: #{e.message}"
    DEVELOPMENT_EMAILS
  end
end
