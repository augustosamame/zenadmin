class ErpMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.railsui_mailer.minimal.subject
  #
  def minimal
    @greeting = "Hi"

    mail to: "to@example.org"
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.railsui_mailer.promotion.subject
  #
  def promotion
    @greeting = "Hi"

    mail to: "to@example.org"
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.railsui_mailer.transactional.subject
  #
  def send_user_invoice(user, invoice_link)
    @invoice_link = invoice_link
    @user = user

    mail to: user.email
  end
end
