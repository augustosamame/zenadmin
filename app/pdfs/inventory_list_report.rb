require "prawn"
require "prawn/table"

class InventoryListReport < Prawn::Document
  def initialize(date, warehouse, products)
    @date = date
    @warehouse = warehouse
    @products = products
    @content_height = measure_content
    super(page_size: [ 222, @content_height + 10 ], margin: [ 5, 5, 5, 5 ])
    generate_content
  end

  def generate_content
    content_generator(self)
  end

  def measure_content
    dummy_document = Prawn::Document.new(page_size: [ 222, 50000 ], margin: [ 5, 5, 5, 5 ])
    content_generator(dummy_document)
    50000 - dummy_document.cursor
  end

  private

  def content_generator(pdf)
    date = @date
    warehouse = @warehouse
    products = @products

    pdf.instance_eval do
      text "Inventario Físico", size: 12, align: :center, style: :bold
      text "#{warehouse.name}", size: 10, align: :center, style: :bold
      move_down 10

      text_box "Fecha: #{I18n.l(date, format: '%d/%m/%y - %H:%M')}",
               size: 9,
               at: [ 0, cursor ],
               width: bounds.width,
               align: :center
      move_down 15

      stroke_horizontal_rule
      move_down 10

      # Products table with additional column
      products_data = [ [ "Producto", "Stock", "Físico" ] ] +
        products.map do |product|
          [
            product.name, # .truncate(32),  # Shortened to accommodate new column
            product.stock(warehouse).to_s,
            "____"  # Empty column for manual counting
          ]
        end

      table products_data do
        cells.padding = 2
        cells.borders = []
        cells.size = 7
        columns(1..2).align = :right
        self.header = true
        self.column_widths = [ 150, 30, 30 ]  # Adjusted widths for three columns
      end

      move_down 10
      stroke_horizontal_rule

      move_down 10
      text "Nombre: _____________________",
           size: 8,
           align: :left
      move_down 10
      text "Firma: _____________________",
           size: 8,
           align: :left
      move_down 10
      text_box "Reporte generado el: #{I18n.l(Time.current, format: '%d/%m/%y - %H:%M:%S')}",
               size: 8,
               at: [ 0, cursor ],
               width: bounds.width
    end
  end
end
