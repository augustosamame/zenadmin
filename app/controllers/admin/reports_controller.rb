# app/controllers/admin/reports_controller.rb
class Admin::ReportsController < Admin::AdminController
  def reports_form
    # This action will render the form
  end

  def generate
    @date = params[:date].present? ? Date.parse(params[:date]) : Date.today
    @location = params[:location].present? ? params[:location] : @current_location
    report_type = params[:report_type]

    respond_to do |format|
      format.html do
        redirect_to admin_reports_path, alert: "Por favor, use el formulario para generar el reporte."
      end
      format.pdf do
        pdf = case report_type
              when 'ventas'
                generate_sales_report
              when 'inventario'
                generate_inventory_report
              when 'caja'
                generate_cash_flow_report
              when 'consolidado'
                generate_consolidated_report
              else
                raise ArgumentError, "Invalid report type: #{report_type}"
              end

        filename = "reporte_#{report_type}_#{@date.strftime('%Y_%m_%d')}.pdf"
        send_data pdf.render, 
                  filename: filename, 
                  type: 'application/pdf', 
                  disposition: 'inline',
                  stream: 'true',
                  buffer_size: '4096'
      end
    end
  end

  private

  def generate_sales_report
    @orders = Order.where(order_date: @date.beginning_of_day..@date.end_of_day)
                   .includes(order_items: :product, user: {})
                   .order(id: :asc)
    @total_sales = Order.where(id: @orders.pluck(:id)).sum(:total_price_cents) / 100.0
    @total_items = @orders.joins(:order_items).sum('order_items.quantity')

    SalesReport.new(@date, @date, @location, @orders, @total_sales, @total_items, current_user)
  end

  def generate_inventory_report
    @stock_transfers = StockTransfer.where(created_at: @date.beginning_of_day..@date.end_of_day)
                                   .where(origin_warehouse_id: @current_warehouse.id)
                                   .includes(:stock_transfer_lines)
                                   .order(id: :asc)
    @total_quantity_out = @stock_transfers.joins(:stock_transfer_lines).sum('stock_transfer_lines.quantity')
    InventoryOutReport.new(@date, @date, @location, @stock_transfers, @total_quantity_out, @current_warehouse, current_user)
  end

  def generate_cash_flow_report
    @cashier_transactions = CashierTransaction.joins(:cashier)
                                          .where(created_at: @date.beginning_of_day..@date.end_of_day)
                                          .where(cashiers: { id: @current_cashier.id })
                                          .order(id: :asc)
    CashFlowReport.new(@date, @date, @location, @cashier_transactions, @current_cashier, current_user)
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
