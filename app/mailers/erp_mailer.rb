class ErpMailer < ApplicationMailer
  def send_user_invoice(user, invoice_link)
    @invoice_link = invoice_link
    @user = user

    mail to: user.email
  end
end
