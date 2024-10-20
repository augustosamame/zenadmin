# app/controllers/admin/reports_controller.rb
class Admin::ReportsController < Admin::AdminController
  def sales_form
    # This action will render the form
  end

  def generate_sales
    @date = params[:date].present? ? Date.parse(params[:date]) : Date.today
    @location = params[:location].present? ? params[:location] : @current_location
    @orders = Order.where(order_date: @date.beginning_of_day..@date.end_of_day)
                   .includes(order_items: :product, user: {})
                   .order(order_date: :asc)
    @total_sales = Order.where(id: @orders.pluck(:id)).sum(:total_price_cents) / 100.0
    @total_items = @orders.joins(:order_items).sum('order_items.quantity')

    respond_to do |format|
      format.html do
        redirect_to admin_reports_sales_path, alert: "Por favor, use el formulario para generar el reporte."
      end
      format.pdf do
        filename = "reporte_ventas_#{@date.strftime('%Y_%m_%d')}.pdf"
        pdf = SalesReport.new(@date, @date, @location, @orders, @total_sales, @total_items, current_user)
        send_data pdf.render, 
                  filename: filename, 
                  type: 'application/pdf', 
                  disposition: 'inline',
                  stream: 'true',
                  buffer_size: '4096'
      end
    end
  end

  def cash_flow
    respond_to do |format|
      format.pdf do
        render pdf: "cash_flow_report",
               template: "reports/cash_flow",
               layout: "pdf",
               page_size: [ 80, 1000 ],
               margin: { top: 5, bottom: 5, left: 5, right: 5 }
      end
    end
  end

  def inventory_out
    respond_to do |format|
      format.pdf do
        render pdf: "inventory_out_report",
               template: "reports/inventory_out",
               layout: "pdf",
               page_size: [ 80, 1000 ],
               margin: { top: 5, bottom: 5, left: 5, right: 5 }
      end
    end
  end

  def consolidated
    respond_to do |format|
      format.pdf do
        render pdf: "consolidated_report",
               template: "reports/consolidated",
               layout: "pdf",
               page_size: [ 80, 1000 ],
               margin: { top: 5, bottom: 5, left: 5, right: 5 }
      end
    end
  end
end
