class Admin::AdminController < ApplicationController
  include LocationManageable

  layout :admin_layout
  helper :admin

  before_action :authenticate_user!, unless: :devise_controller?
  before_action :set_current_objects
  before_action :force_temp_password_change
  before_action :check_for_admin_login_as_token

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.html { redirect_to admin_sales_dashboard_path, alert: "No tienes permiso para acceder a esta página." }
      format.json { render json: { error: "Acceso denegado" }, status: :forbidden }
    end
  end

  def set_current_objects
    @current_warehouse = Warehouse.find_by(id: session[:current_warehouse_id] || current_user&.warehouse_id || @current_location&.warehouses&.first&.id || Warehouse.find_by(is_main: true) || Warehouse.find_by(name: "Almacén Oficina Principal"))
    session[:current_warehouse_id] = @current_warehouse&.id
    current_cashier = Cashier.find_by(id: session[:current_cashier_id])
    @current_cashier = current_cashier || @current_location&.cashiers&.first
    session[:current_cashier_id] = @current_cashier&.id
    @current_cashier_shift = @current_cashier&.current_shift(current_user)
    @default_object_options_array = [
      { event_name: "edit", label: "Editar", icon: "pencil-square" },
      { event_name: "delete", label: "Eliminar", icon: "trash" }
    ]
  end

  def admin_layout
    return "turbo_rails/frame" if turbo_frame_request?
    "admin"
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
