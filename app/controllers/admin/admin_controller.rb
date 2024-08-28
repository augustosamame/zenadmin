class Admin::AdminController < ApplicationController
	layout "admin"
  helper :admin

  before_action :authenticate_user!, unless: :devise_controller?
  before_action :set_current_objects
  before_action :force_temp_password_change
  before_action :check_for_admin_login_as_token

  def set_current_objects
    @current_location = Location.find_by(id: session[:current_location_id] || current_user&.location_id || Location.first.id)
    session[:current_location_id] = @current_location.id
    @current_warehouse = Warehouse.find_by(id: session[:current_warehouse_id] || current_user&.warehouse_id || @current_location&.warehouses&.first&.id)
    session[:current_warehouse_id] = @current_warehouse.id
    current_cashier = Cashier.find_by(id: session[:current_cashier_id])
    @current_cashier = current_cashier || @current_location&.cashiers&.first
    @current_cashier_shift = @current_cashier&.current_shift(current_user)
    @default_object_options_array = [
      { event_name: "edit", label: "Editar", icon: "pencil-square" },
      { event_name: "delete", label: "Eliminar", icon: "trash" }
    ]
  end

  def force_temp_password_change
    if current_user.require_password_change? && session[:admin_login_as_token].blank?
      unless params[:controller] == "admin/users" && [ "edit_temp_password", "update_temp_password" ].include?(params[:action])
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
