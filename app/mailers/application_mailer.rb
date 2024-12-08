class ApplicationMailer < ActionMailer::Base
  helper Railsui::MailHelper
  add_template_helper(MailerHelper)

  default from: email_address_with_name("#{ENV["SUPPORT_EMAIL"]}", "#{ENV["APPLICATION_NAME"]}")
  layout "mailer"
end
