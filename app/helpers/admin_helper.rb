module AdminHelper

  def draft_order_present?
    session[:draft_order].present?
  end

  def friendly_date(user, passed_datetime, already_local = false)
    if passed_datetime
      if already_local
        passed_datetime.strftime("%d/%m/%Y | %H:%M")
      else
        user_time_zone = user.try(:time_zone) || "Lima"
        passed_datetime.in_time_zone(user_time_zone).strftime("%d/%m/%Y | %H:%M")
      end
    else
      ""
    end
  end

  def name_with_location_warehouse(warehouse)
    if warehouse&.location&.name
      "#{warehouse&.location&.name} - #{warehouse.name}"
    else
      warehouse.name
    end
  end


  def render_select_warehouse_dropdown(current_user)
    if current_user.has_role?("admin") || current_user.has_role?("super_admin")
      render "admin/warehouses/select_warehouse_dropdown"
    end
  end

end