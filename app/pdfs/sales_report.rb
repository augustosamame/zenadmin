require 'prawn'
require 'prawn/table'

class SalesReport < Prawn::Document
  def initialize(start_date, end_date, location, orders, total_price, total_items, current_user)
    @start_date = start_date
    @end_date = end_date
    @location = location
    @orders = orders
    @total_price = total_price
    @total_items = total_items
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
    orders = @orders
    location = @location
    total_price = @total_price
    total_items = @total_items
    current_user = @current_user
    pdf.instance_eval do
      text "Reporte Diario de Ventas", size: 12, align: :center, style: :bold
      text "Tienda: #{location&.name}", size: 10, align: :center, style: :bold
      move_down 10
      text_box "Fecha inicio: #{I18n.localize(start_date, format: "%d/%m/%y")}", size: 9, at: [0, cursor], width: 100
      text_box "Fecha fin: #{I18n.localize(end_date, format: "%d/%m/%y")}", size: 9, at: [110, cursor], width: 100, align: :right
      move_down 15
      stroke_horizontal_rule
      move_down 10

      text "Resumen", size: 10, style: :bold
      move_down 5
      text "Total de Órdenes: #{orders.count}", size: 8
      text "Total de Items: #{total_items}", size: 8
      text "Total de Ventas: S/ #{sprintf("%.2f", total_price)}", size: 8
      move_down 10
      stroke_horizontal_rule
      move_down 10

      orders.each do |order|
        text_box "Venta ##{order.custom_id}", size: 10, style: :bold, at: [0, cursor], width: 100
        text_box "Hora: #{order.order_date.strftime("%H:%M")}", size: 10, at: [110, cursor], width: 100, align: :right
        move_down 15
        text_box "Cliente: #{order.customer.name}", size: 8, at: [0, cursor], width: 100
        text_box order.invoice&.custom_id.blank? ? "Error en Comprobante" : order.invoice&.custom_id, size: 8, at: [110, cursor], width: 100, align: :right
        move_down 15

        order_items_data = [["Producto", "Cant", "Precio", "Total"]] +
          order.order_items.map do |item|
            [item.product.name.truncate(20),
             item.quantity,
             "S/ #{sprintf("%.2f", item.price)}",
             "S/ #{sprintf("%.2f", item.quantity * item.price)}"]
          end

        table order_items_data do
          cells.padding = 2
          cells.borders = []
          cells.size = 7
          columns(1..3).align = :right
          self.header = true
          self.column_widths = [90, 30, 45, 45]
        end
        
        move_down 10
        if order.total_discount > 0
          text "Subtotal: S/ #{sprintf("%.2f", order.original_price)}", size: 9, align: :right, style: :bold
          move_down 10
          text "Descuento: S/ #{sprintf("%.2f", order.total_discount)}", size: 9, align: :right, style: :bold
          move_down 10
          text "Total: S/ #{sprintf("%.2f", order.total_price)}", size: 9, align: :right, style: :bold
        else
          text "Total: S/ #{sprintf("%.2f", order.total_price)}", size: 9, align: :right, style: :bold
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
