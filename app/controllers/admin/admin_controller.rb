class Admin::AdminController < ApplicationController
	layout "admin"
  
  before_action :set_current_objects

  def set_current_objects
    session[:current_warehouse_id] ||= Warehouse.first.id
    @current_warehouse = Warehouse.find_by(id: session[:current_warehouse_id])
  end

end
