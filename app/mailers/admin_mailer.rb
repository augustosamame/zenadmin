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

    mail to: super_admin_users.pluck(:email), cc: "augusto@devtechperu.com"
  end

  def missing_stock_periodic_inventory
    @notification = params[:notification]
    @periodic_inventory = @notification.notifiable
    if ENV["RAILS_ENV"] == "production"
      super_admin_users = User.with_role("super_admin")
    else
      super_admin_users = User.where(email: "augusto@devtechperu.com")
    end

    mail to: super_admin_users.pluck(:email), cc: "augusto@devtechperu.com"
  end
end
