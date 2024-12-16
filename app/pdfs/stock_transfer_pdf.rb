class StockTransferPdf < Prawn::Document
  def initialize(stock_transfer, view)
    super(page_size: "A4")
    @stock_transfer = stock_transfer
    @view = view

    header
    stock_transfer_details
    products_table
    footer
  end

  def header
    text "Transferencia de Stock #{@stock_transfer.custom_id}", size: 16, style: :bold
    move_down 20
  end

  def stock_transfer_details
    details = [
      [ "Fecha:", @view.friendly_date(@view.current_user, @stock_transfer.transfer_date) ],
      [ "Origen:", @stock_transfer.origin_warehouse&.name || "Inventario Inicial" ],
      [ "Destino:", @stock_transfer.destination_warehouse&.name ],
      [ "Estado:", @stock_transfer.translated_status ],
      [ "Etapa:", @view.translated_stage(@stock_transfer.stage) ],
      [ "Usuario:", @stock_transfer.user&.name ],
      [ "Comentarios:", @stock_transfer.comments ]
    ]

    table(details, cell_style: { borders: [], padding: [ 2, 5 ] }) do
      columns(0).font_style = :bold
    end
    move_down 20
  end

  def products_table
    text "Productos", size: 14, style: :bold
    move_down 10

    headers = [ "Producto", "Cantidad" ]
    headers << "Cantidad Recibida" if @stock_transfer.complete?

    data = [ headers ]
    @stock_transfer.stock_transfer_lines.includes(:product).each do |line|
      row = [ line.product.name, line.quantity ]
      row << line.received_quantity if @stock_transfer.complete?
      data << row
    end

    table(data, header: true, width: bounds.width) do
      row(0).font_style = :bold
      cells.padding = [ 5, 5 ]
      cells.borders = [ :bottom, :top ]
    end
  end

  def footer
    move_down 30
    text "Generado el #{Time.current.strftime('%d/%m/%Y %H:%M')}", size: 8, align: :right
  end
end
