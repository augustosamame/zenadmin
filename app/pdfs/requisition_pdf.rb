require "prawn"
require "prawn/table"

class RequisitionPdf < Prawn::Document
  include AdminHelper

  def initialize(requisition, current_user)
    @requisition = requisition
    @current_user = current_user
    @content_height = measure_content
    super(page_size: "A4", margin: [ 30, 30, 30, 30 ])
    generate_content
  end

  def generate_content
    content_generator(self)
  end

  def measure_content
    dummy_document = Prawn::Document.new(page_size: "A4", margin: [ 30, 30, 30, 30 ])
    content_generator(dummy_document)
    dummy_document.cursor # This gives us the height of the content
  end

  private

  def content_generator(pdf)
    requisition = @requisition
    current_user = @current_user
    helper = self

    pdf.instance_eval do
      # Header
      text "Pedido ##{requisition.custom_id}", size: 16, align: :center, style: :bold
      move_down 20

      # Requisition Details
      details_data = [
        [ "Fecha:", I18n.l(requisition.requisition_date, format: :long) ],
        [ "Usuario:", requisition.user.name ],
        [ "Ubicación:", requisition.location.name ],
        [ "Almacén:", requisition.warehouse.name ],
        [ "Etapa:", helper.translated_requisition_stage(requisition.stage) ],
        [ "Estado:", requisition.translated_status ],
        [ "Comentarios:", requisition.comments.presence || "N/A" ]
      ]

      table details_data do
        cells.padding = [ 5, 10 ]
        cells.borders = []
        column(0).font_style = :bold
        column(0).width = 120
        column(1).width = 400
        self.cell_style = { size: 10 }
      end

      move_down 30

      # Products Table
      text "Artículos del Pedido", size: 14, style: :bold
      move_down 10

      products_data = [
        [
          "Producto",
          "Stock\nActual",
          "Cantidad\nAutomática",
          "Cantidad\nPrevendida",
          "Cantidad\nPedida",
          "Cantidad\nPlanificada",
          "Estado"
        ]
      ]

      warehouse = requisition.location.warehouses.first
      warehouse_inventories = warehouse.warehouse_inventories.index_by(&:product_id)

      requisition.requisition_lines.includes(:product).where("manual_quantity > 0 OR planned_quantity > 0").joins(:product).order("products.name ASC").each do |line|
        products_data << [
          line.product.name,
          warehouse_inventories[line.product_id]&.stock || 0,
          line.automatic_quantity.to_s,
          line.presold_quantity.to_s,
          line.manual_quantity.to_s,
          line.planned_quantity.to_s,
          line.translated_status
        ]
      end

      table products_data do
        cells.padding = [ 5, 5 ]
        row(0).font_style = :bold
        row(0).background_color = "F0F0F0"
        self.header = true
        self.cell_style = { size: 9 }
        self.column_widths = {
          0 => 165,  # Product name
          1 => 45,   # Stock actual
          2 => 60,   # Automatic quantity
          3 => 60,   # Presold quantity
          4 => 60,   # Manual quantity
          5 => 60,   # Planned quantity
          6 => 55    # Status
        }
      end

      move_down 30

      # Footer
      text "Documento generado el #{I18n.l(Time.current, format: :long)}", size: 8
      text "por el usuario: #{current_user.email}", size: 8

      # Page numbers
      number_pages "Página <page> de <total>",
                  at: [ bounds.right - 150, 0 ],
                  width: 150,
                  align: :right,
                  size: 8
    end
  end
end
