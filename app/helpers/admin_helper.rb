module AdminHelper
  def draft_order_present?
    session[:draft_order].present?
  end

  def friendly_date(user, passed_datetime, time = true, already_local = false)
    if passed_datetime
      if already_local
        if time
          passed_datetime.strftime("%d/%m/%Y | %H:%M")
        else
          passed_datetime.strftime("%d/%m/%Y")
        end
      else
        user_time_zone = user.try(:time_zone) || "Lima"
        if time
          passed_datetime.in_time_zone(user_time_zone).strftime("%d/%m/%Y | %H:%M")
        else
          passed_datetime.in_time_zone(user_time_zone).strftime("%d/%m/%Y")
        end
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

  def name_with_location_cashier(cashier)
    if cashier&.location&.name
      "#{cashier&.location&.name} - #{cashier.name}"
    else
      cashier.name
    end
  end


  def render_select_warehouse_dropdown(current_user)
    if current_user.has_role?("admin") || current_user.has_role?("super_admin")
      render "admin/warehouses/select_warehouse_dropdown"
    end
  end

  def transaction_type_color(transaction)
    case transaction.transactable_type
    when "CashInflow"
      "bg-green-100 text-green-800"
    when "CashOutflow"
      "bg-red-100 text-red-800"
    when "Payment"
      "bg-blue-100 text-blue-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def friendly_transactable_type(transaction)
    case transaction.transactable_type
    when "Payment"
      "Pago por Venta"
    when "CashInflow"
      "Entrada de Caja"
    when "CashOutflow"
      "Salida de Caja"
    else
      "Transacción"
    end
  end

  def seller_comission_percentage(location)
    CommissionRange.find_commission_for_sales(Services::Queries::SalesSearchService.new(location: location).sales_on_month_for_location, location)&.commission_percentage || 0
  end
end
