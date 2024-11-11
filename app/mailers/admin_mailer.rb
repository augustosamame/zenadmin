class AdminMailer < ApplicationMailer
  layout "admin_mailer"

  def partial_stock_transfer
    @notification = params[:notification]
    @stock_transfer = @notification.notifiable
    if ENV["RAILS_ENV"] == "production"
      super_admin_users = User.with_role("super_admin")
    else
      super_admin_users = User.where(email: "augusto@devtechperu.com")
    end

    mail subject: @notification.message_title, to: super_admin_users.pluck(:email), cc: "augusto@devtechperu.com"
  end

  def missing_stock_periodic_inventory
    @notification = params[:notification]
    @periodic_inventory = @notification.notifiable
    if ENV["RAILS_ENV"] == "production"
      super_admin_users = User.with_role("super_admin")
    else
      super_admin_users = User.where(email: "augusto@devtechperu.com")
    end

    mail subject: @notification.message_title, to: super_admin_users.pluck(:email), cc: "augusto@devtechperu.com"
  end

  def requisition
    @notification = params[:notification]
    @requisition = @notification.notifiable
    if ENV["RAILS_ENV"] == "production"
      @requisition_notifiable_user_emails = [ "asistentecontable@aromaterapia.com.pe", "administrador@aromaterapia.com.pe", "asistenteadministrativo@aromaterapia.com.pe" ] # TODO: change this to dynamic emails per organization
    else
      @requisition_notifiable_user_emails = [ "augusto@devtechperu.com" ]
    end

    mail subject: @notification.message_title, to: @requisition_notifiable_user_emails, cc: "augusto@devtechperu.com"
  end
end
