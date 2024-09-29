class ApplicationMailer < ActionMailer::Base
  helper Railsui::MailHelper

  default from: email_address_with_name("#{ENV["SUPPORT_EMAIL"]}", "#{ENV["APPLICATION_NAME"]}")
  layout "mailer"
end
