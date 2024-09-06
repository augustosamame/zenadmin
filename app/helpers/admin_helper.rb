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

  def show_invoice_actions(order)
    if order.last_issued_ok_invoice_urls.present?
      order.last_issued_ok_invoice_urls.map do |label, url|
        link_to label, url, target: "_blank", class: "text-blue-600 hover:text-blue-800 underline"
      end.join(", ").html_safe
    else
      if order.invoices.present?
        content_tag(:div, class: "flex items-center space-x-2", data: { controller: "invoice-error-modal", invoice_error_modal_order_id_value: order.id }) do
          concat(button_tag "Error", type: "button", class: "text-red-600 underline cursor-pointer", data: { action: "click->invoice-error-modal#open" })
          concat(button_tag "Reenviar", type: "button", class: "btn btn-sm btn-primary", data: {
            action: "click->invoice-error-modal#resendInvoice",
            invoice_error_modal_order_id_param: order.id
          })
          concat(content_tag(:div, class: "hidden fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full", data: { invoice_error_modal_target: "modal" }) do
            content_tag(:div, class: "relative top-1/4 mx-auto p-5 border w-full max-w-4xl shadow-lg rounded-md bg-white") do
              concat(content_tag(:h3, "Error al emitir el Comprobante", class: "text-lg font-bold mb-4"))
              concat(content_tag(:p, order.invoices.last.invoice_sunat_response, class: "mb-4 overflow-auto max-h-96"))
              concat(button_tag "Cerrar", type: "button", class: "btn btn-sm btn-secondary", data: { action: "click->invoice-error-modal#close" })
            end
          end)
        end
      else
        "Aún no emitida"
      end
    end
  end
end
