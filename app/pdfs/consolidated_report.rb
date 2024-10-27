require "prawn"
require "prawn/table"

class ConsolidatedReport < Prawn::Document
  def initialize(date, location, sales_report, inventory_report, cash_flow_report, current_user)
    @date = date
    @location = location
    @sales_report = sales_report
    @inventory_report = inventory_report
    @cash_flow_report = cash_flow_report
    @current_user = current_user

    # Initialize with a very long page to accommodate all content
    super(page_size: [ 222, 50000 ], margin: [ 5, 5, 5, 5 ])
    generate_content
  end

  private

  def generate_content
    # Add a title for the consolidated report
    text "Reporte Consolidado", size: 14, align: :center, style: :bold
    text "Fecha: #{I18n.localize(@date, format: "%d/%m/%y")}", size: 10, align: :center
    text "Tienda: #{@location.name}", size: 10, align: :center
    move_down 20

    # Sales Report
    @sales_report.generate_content
    move_down 30

    # Inventory Report
    @inventory_report.generate_content
    move_down 30

    # Cash Flow Report
    @cash_flow_report.generate_content
    move_down 30

    # Add footer
    text "Reporte generado el: #{I18n.localize(Time.current, format: "%d/%m/%y - %H:%M:%S")}", size: 8
    text "por el usuario: #{@current_user.email}", size: 8
  end
end
