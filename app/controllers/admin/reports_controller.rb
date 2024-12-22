# app/controllers/admin/reports_controller.rb
class Admin::ReportsController < Admin::AdminController
  def reports_form
    @selected_date = session[:selected_report_date] || params[:date] || Date.current
    @selected_location = if current_user.any_admin_or_supervisor?
      Location.find_by(id: session[:location_id]) || @current_location
    else
      @current_location
    end
    Rails.logger.debug "Reports form loaded with date: #{@selected_date}, location: #{@selected_location&.name}"
  end

  def generate
    @date = if params[:date].present?
      parsed_date = Date.parse(params[:date])
      session[:selected_report_date] = parsed_date
      Rails.logger.debug "Saving date to session: #{parsed_date}"
      parsed_date
    else
      Date.current
    end

    @location = if current_user.any_admin_or_supervisor?
      Location.find_by(id: session[:location_id]) || @current_location
    else
      @current_location
    end

    report_type = params[:report_type]
    Rails.logger.debug "Generating report for date: #{@date}, type: #{report_type}, location: #{@location.name}"

    respond_to do |format|
      format.html do
        redirect_to admin_reports_path, alert: "Por favor, use el formulario para generar el reporte."
      end
      format.pdf do
        pdf_content = case report_type
        when "ventas"
                        generate_sales_report
        when "inventario"
                        generate_inventory_report
        when "caja"
                        generate_cash_flow_report
        when "consolidado"
                        generate_consolidated_report
        else
                        raise ArgumentError, "Invalid report type: #{report_type}"
        end

        filename = "reporte_#{report_type}_#{@date.strftime('%Y_%m_%d')}.pdf"
        send_data pdf_content,
                  filename: filename,
                  type: "application/pdf",
                  disposition: "inline",
                  stream: "true",
                  buffer_size: "4096"
      end
    end
  end

  private

  def generate_sales_report
    @orders = Order.where(location: @location, order_date: @date.beginning_of_day..@date.end_of_day)
                   .includes(order_items: :product, user: {})
                   .order(id: :asc)
    @total_sales = Order.where(id: @orders.pluck(:id)).sum(:total_price_cents) / 100.0
    @total_items = @orders.joins(:order_items).sum("order_items.quantity")

    SalesReport.new(@date, @date, @location, @orders, @total_sales, @total_items, current_user).render
  end

  def generate_inventory_report
    @stock_transfers = StockTransfer.where(created_at: @date.beginning_of_day..@date.end_of_day)
                                  .where(origin_warehouse_id: @current_warehouse.id)
                                  .includes(:stock_transfer_lines)
                                  .order(id: :asc)
    @total_quantity_out = @stock_transfers.joins(:stock_transfer_lines)
                                        .sum("ABS(stock_transfer_lines.quantity)")
    InventoryOutReport.new(@date, @date, @location, @stock_transfers, @total_quantity_out, @current_warehouse, current_user).render
  end

  def generate_cash_flow_report
    @cashier_shifts = CashierShift.joins(:cashier)
                             .where(cashiers: { location_id: @location.id })
                             .where(created_at: @date.beginning_of_day..@date.end_of_day)
                             .where(cashiers: { id: @current_cashier.id })
                             .order(id: :asc)
    @seller_totals = Commission.joins(:user)
                          .joins(:order)
                          .where(orders: { location: @location })
                          .where(commissions: { created_at: @date.beginning_of_day..@date.end_of_day })
                          .group("users.id")
                          .sum(:sale_amount_cents)
                          .transform_values { |cents| cents / 100.0 }
                          .sort_by { |_, total| -total }

    CashFlowReport.new(@date, @date, @location, @cashier_shifts, @current_cashier, current_user, @seller_totals).render
  end

  def generate_consolidated_report
    sales_report = generate_sales_report
    inventory_report = generate_inventory_report
    cash_flow_report = generate_cash_flow_report

    combined_pdf = CombinePDF.new
    [ sales_report, inventory_report, cash_flow_report ].each do |report|
      combined_pdf << CombinePDF.parse(report)
    end

    combined_pdf.to_pdf
  end
end
