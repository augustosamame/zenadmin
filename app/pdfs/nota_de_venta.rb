require "prawn"
require "prawn/table"

class NotaDeVenta < Prawn::Document
  def initialize(order, current_user)
    @order = order
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
    order = @order
    current_user = @current_user
    pdf.instance_eval do
      text "Nota de Venta", size: 12, align: :center, style: :bold
      move_down 10
      text "#{Invoicer.first.razon_social}", size: 10, align: :center, style: :bold
      text "Tienda: #{order.location&.name}", size: 10, align: :center, style: :bold
      move_down 10
      text_box "Fecha: #{I18n.localize(order.order_date, format: "%d/%m/%y")}", size: 9, at: [ 0, cursor ], width: 100
      text_box "Hora: #{order.order_date.strftime("%H:%M")}", size: 9, at: [ 110, cursor ], width: 100, align: :right
      move_down 15
      stroke_horizontal_rule
      move_down 10

      # Order details
      text "Detalle de Venta ##{order.custom_id}", size: 10, style: :bold
      move_down 5

      # Customer details
      if order.user.present?
        text "Cliente: #{order.user.name}", size: 8
        if order.user.customer.present?
          text "DNI/RUC: #{order.user.customer.doc_id || order.user.customer.factura_ruc || 'No especificado'}", size: 8
          text "Teléfono: #{order.user.phone || 'No especificado'}", size: 8
        end
      else
        text "Cliente: No especificado", size: 8
      end

      move_down 10
      stroke_horizontal_rule
      move_down 10

      # Order items
      text "Productos", size: 10, style: :bold
      move_down 5

      order_items_data = [ [ "Producto", "Cant", "Precio", "Total" ] ] +
        order.order_items.map do |item|
          [ item.product.name,
           item.quantity,
           "S/ #{sprintf("%.2f", item.price)}",
           "S/ #{sprintf("%.2f", item.quantity * item.price)}" ]
        end

      table order_items_data do
        cells.padding = 2
        cells.borders = []
        cells.size = 7
        columns(1..3).align = :right
        self.header = true
        self.column_widths = [ 100, 20, 45, 45 ]
      end

      move_down 10

      # Totals
      if order.total_discount > 0
        text "Subtotal: S/ #{sprintf("%.2f", (order.total_price + order.total_discount))}", size: 9, align: :right, style: :bold
        move_down 5
        text "Descuento: S/ #{sprintf("%.2f", order.total_discount)}", size: 9, align: :right, style: :bold
        move_down 5
      end

      text "Total: S/ #{sprintf("%.2f", order.total_price)}", size: 9, align: :right, style: :bold
      move_down 10
      stroke_horizontal_rule
      move_down 10

      # Payment information
      text "Información de Pagos", size: 10, style: :bold
      move_down 5

      if order.payments.any?
        payments_data = [ [ "Método", "Fecha", "Monto" ] ] +
          order.payments.map do |payment|
            [ payment.payment_method.description,
             I18n.localize(payment.payment_date, format: "%d/%m/%y"),
             "S/ #{sprintf("%.2f", payment.amount)}" ]
          end

        table payments_data do
          cells.padding = 2
          cells.borders = []
          cells.size = 7
          columns(2).align = :right
          self.header = true
          self.column_widths = [ 80, 60, 70 ]
        end
      else
        text "No hay pagos registrados", size: 8
      end

      move_down 10

      # Credit information
      if order.account_receivables.any?
        stroke_horizontal_rule
        move_down 10
        text "Pagos al Crédito Pendientes", size: 10, style: :bold
        move_down 5

        receivables_data = [ [ "Monto", "Fecha Vencimiento", "Estado" ] ] +
          order.account_receivables.map do |receivable|
            [
              "S/ #{sprintf("%.2f", receivable.amount)}",
              receivable.due_date ? I18n.localize(receivable.due_date, format: "%d/%m/%y") : "No especificado",
              receivable.translated_status
            ]
          end

        table receivables_data do
          cells.padding = 2
          cells.borders = []
          cells.size = 7
          columns(0).align = :right
          self.header = true
          self.column_widths = [ 70, 80, 60 ]
        end
      end

      move_down 15
      stroke_horizontal_rule
      move_down 10

      # Footer
      text_box "Documento generado el: #{I18n.localize(Time.current, format: "%d/%m/%y - %H:%M:%S")}", size: 8, at: [ 0, cursor ], width: 200
      move_down 10
      text_box "por: #{current_user.email}", size: 8, at: [ 0, cursor ], width: 200
      move_down 20
      text "¡Gracias por su compra!", size: 9, align: :center, style: :bold
    end
  end
end
