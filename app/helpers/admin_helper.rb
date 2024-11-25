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

  def translated_payable_type(payable_type)
    case payable_type
    when "Order"
      "Venta"
    when nil
      ""
    else
      payable_type
    end
  end

  def seller_comission_percentage(location)
    CommissionRange.find_commission_for_sales(Services::Queries::SalesSearchService.new(location: location).sales_on_month_for_location, location, Time.current)&.commission_percentage || 0
  end

  def show_invoice_actions(order, format = "pdf")
    if order.last_issued_ok_invoice_urls.present?
      order.last_issued_ok_invoice_urls.map do |label, url|
        if format == "xml"
          url = url.gsub(".pdf", ".xml")
          label = "Descargar XML"
        end
        link_to label, url, target: "_blank", class: "text-blue-600 hover:text-blue-800 underline"
      end.join(", ").html_safe
    else
      if order.invoices.present? && format == "pdf"
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
        if format == "pdf"
          "Aún no emitida"
        else
          ""
        end
      end
    end
  end

  def report_button_class(report_type)
    case report_type
    when "ventas"
      "bg-primary-500 hover:bg-primary-600"
    when "inventario"
      "bg-green-500 hover:bg-green-600"
    when "caja"
      "bg-yellow-500 hover:bg-yellow-600"
    when "consolidado"
      "bg-red-500 hover:bg-red-600"
    else
      "bg-gray-500 hover:bg-gray-600"
    end
  end

  def whatsapp_icon
    content_tag :svg, class: "inline-block w-5 h-5", fill: "currentColor", viewBox: "0 0 24 24" do
      content_tag :path, nil, d: "M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z"
    end
  end

  def smart_notification_linker(notification)
    if notification.notifiable.present?
      case notification.notifiable.class.name
      when "Order"
        link_to notification.message_body, admin_order_path(notification.notifiable)
      else
        notification.message_title
      end
    else
      notification.message_title
    end
  end

  def achievement_background(percentage)
    case
    when percentage >= 100
      "bg-amber-300"  # Rich golden
    when percentage >= 75
      "bg-green-300"  # Rich green
    else
      "bg-red-300"    # Rich red
    end
  end

  def translated_requisition_stage(stage)
    case stage
    when "req_draft"
      "Borrador"
    when "req_submitted"
      "Enviado"
    when "req_planned"
      "Planificado"
    when "req_pending"
      "Pendiente"
    when "req_fulfilled"
      "Cumplido"
    end
  end
end
