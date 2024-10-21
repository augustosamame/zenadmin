require 'prawn'
require 'prawn/table'

class CashFlowReport < Prawn::Document
  def initialize(start_date, end_date, location, cashier_transactions, current_cashier, current_user)
    @start_date = start_date
    @end_date = end_date
    @location = location
    @cashier_transactions = cashier_transactions
    @current_cashier = current_cashier
    @current_user = current_user
    @content_height = measure_content
    super(page_size: [222, @content_height + 10], margin: [5, 5, 5, 5]) # Add a small buffer
    generate_content
  end

  def generate_content
    content_generator(self)
  end

  def measure_content
    dummy_document = Prawn::Document.new(page_size: [222, 50000], margin: [5, 5, 5, 5])
    content_generator(dummy_document)
    50000 - dummy_document.cursor # This gives us the height of the content
  end

  private

  def content_generator(pdf)
    start_date = @start_date
    end_date = @end_date
    cashier_transactions = @cashier_transactions
    location = @location
    current_cashier = @current_cashier
    current_user = @current_user
    pdf.instance_eval do
      text "Reporte Diario de Salidas de Almacén", size: 12, align: :center, style: :bold
      text "Tienda: #{location&.name}", size: 10, align: :center, style: :bold
      move_down 10
      text_box "Fecha inicio: #{I18n.localize(start_date, format: "%d/%m/%y")}", size: 9, at: [0, cursor], width: 100
      text_box "Fecha fin: #{I18n.localize(end_date, format: "%d/%m/%y")}", size: 9, at: [110, cursor], width: 100, align: :right
      move_down 15
      stroke_horizontal_rule
      move_down 10

      text "Resumen", size: 10, style: :bold
      move_down 5
      text "Total de Transacciones: #{cashier_transactions.count}", size: 8
      move_down 10
      stroke_horizontal_rule
      move_down 10

      cashier_transactions.each do |cashier_transaction|
        text_box "Transferencia ##{cashier_transaction.id}", size: 10, style: :bold, at: [0, cursor], width: 130
        text_box "Hora: #{cashier_transaction.created_at.strftime("%H:%M")}", size: 10, at: [130, cursor], width: 80, align: :right
        move_down 15
        text_box "Destino: #{cashier_transaction.transactable_type}", size: 8, at: [0, cursor], width: 200
        move_down 15

        cashier_transaction_lines_data = [["Tx", "Tipo", "Medio", "Monto"]]

        cashier_transactions.each do |cashier_transaction|
          cashier_transaction_lines_data << [
            cashier_transaction.id,
            cashier_transaction.transactable_type,
            cashier_transaction.payment_method.name,
            sprintf("S/ %.2f", cashier_transaction.amount)
          ]
        end

        table cashier_transaction_lines_data do
          cells.padding = 2
          cells.borders = []
          cells.size = 7
          columns(0).align = :left
          columns(1..3).align = :right
          self.header = true
          self.column_widths = [30, 60, 60, 50]
        end
        
        move_down 10
        stroke_horizontal_rule
        move_down 10
      end
      move_down 10
      text_box "Reporte generado el: #{I18n.localize(Time.now, format: "%d/%m/%y - %H:%M:%S")}", size: 8, at: [0, cursor], width: 200
      move_down 10
      text_box "por el usuario: #{current_user.email}", size: 8, at: [0, cursor], width: 200
    end
  end
end
