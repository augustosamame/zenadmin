class Admin::AdminController < ApplicationController
	layout "admin"

  before_action :authenticate_user!, unless: :devise_controller?
  before_action :set_current_objects
  before_action :force_temp_password_change
  before_action :check_for_admin_login_as_token

  def set_current_objects
    session[:current_warehouse_id] ||= Warehouse.first.id
    @current_warehouse = Warehouse.find_by(id: session[:current_warehouse_id])
    @default_object_options_array = [
      { event_name: "edit", label: "Editar", icon: "pencil-square" },
      { event_name: "delete", label: "Eliminar", icon: "trash" }
    ]
  end

  def force_temp_password_change
    if current_user.require_password_change? && session[:admin_login_as_token].blank?
      unless params[:controller] == 'admin/users' && ['edit_temp_password', 'update_temp_password'].include?(params[:action])
        redirect_to admin_edit_temp_password_path
      end
    end
  end

  def check_for_admin_login_as_token
    if session[:admin_login_as_token].present?
      @admin_login_as_token = true
    end
  end

  private


  

end