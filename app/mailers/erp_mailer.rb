class ErpMailer < ApplicationMailer
  def send_user_invoice(order, user, invoice_link)
    @invoice_link = invoice_link
    @order = order
    @user = user

    mail to: user.email
  end
end
