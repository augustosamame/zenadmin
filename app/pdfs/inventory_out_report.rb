require "prawn"
require "prawn/table"

class InventoryOutReport < Prawn::Document
  def initialize(start_date, end_date, location, stock_transfers, total_items, current_warehouse, current_user)
    @start_date = start_date
    @end_date = end_date
    @location = location
    @stock_transfers = stock_transfers
    @total_items = total_items
    @current_warehouse = current_warehouse
    @current_user = current_user
    @content_height = measure_content
    super(page_size: [ 222, @content_height + 10 ], margin: [ 5, 5, 5, 5 ]) # Add a small buffer
    generate_content
  end

  def generate_content
    content_generator(self)
  end

  def measure_content
    dummy_document = Prawn::Document.new(page_size: [ 222, 50000 ], margin: [ 5, 5, 5, 5 ])
    content_generator(dummy_document)
    50000 - dummy_document.cursor # This gives us the height of the content
  end

  private

  def content_generator(pdf)
    start_date = @start_date
    end_date = @end_date
    stock_transfers = @stock_transfers
    total_items = @total_items
    location = @location
    current_warehouse = @current_warehouse
    current_user = @current_user
    pdf.instance_eval do
      text "Reporte Diario de Salidas de Almacén", size: 12, align: :center, style: :bold
      text "Tienda: #{location&.name}", size: 10, align: :center, style: :bold
      move_down 10
      text_box "Fecha inicio: #{I18n.localize(start_date, format: "%d/%m/%y")}", size: 9, at: [ 0, cursor ], width: 100
      text_box "Fecha fin: #{I18n.localize(end_date, format: "%d/%m/%y")}", size: 9, at: [ 110, cursor ], width: 100, align: :right
      move_down 15
      stroke_horizontal_rule
      move_down 10

      text "Resumen", size: 10, style: :bold
      move_down 5
      text "Total de Transferencias: #{stock_transfers.count}", size: 8
      text "Total de Items: #{total_items}", size: 8
      move_down 10
      stroke_horizontal_rule
      move_down 10

      stock_transfers.each do |stock_transfer|
        text_box "Transferencia ##{stock_transfer.custom_id}", size: 10, style: :bold, at: [ 0, cursor ], width: 130
        text_box "Hora: #{stock_transfer.transfer_date.strftime("%H:%M")}", size: 10, at: [ 130, cursor ], width: 80, align: :right
        move_down 15
        text_box "Destino: #{stock_transfer.destination_warehouse.name}", size: 8, at: [ 0, cursor ], width: 200
        move_down 15

        stock_transfer_lines_data = [ [ "Producto", "Cant" ] ] +
          stock_transfer.stock_transfer_lines.map do |line|
            [ line.product.name.truncate(40),
             line.quantity ]
          end

        table stock_transfer_lines_data do
          cells.padding = 2
          cells.borders = []
          cells.size = 7
          columns(1..3).align = :right
          self.header = true
          self.column_widths = [ 170, 40 ]
        end

        move_down 10
        stroke_horizontal_rule
        move_down 10
      end
      move_down 10
      text_box "Reporte generado el: #{I18n.localize(Time.current, format: "%d/%m/%y - %H:%M:%S")}", size: 8, at: [ 0, cursor ], width: 200
      move_down 10
      text_box "por el usuario: #{current_user.email}", size: 8, at: [ 0, cursor ], width: 200
    end
  end
end
