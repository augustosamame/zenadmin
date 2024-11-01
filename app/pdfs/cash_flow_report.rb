require "prawn"
require "prawn/table"

class CashFlowReport < Prawn::Document
  include AdminHelper
  def initialize(start_date, end_date, location, cashier_shifts, current_cashier, current_user)
    @start_date = start_date
    @end_date = end_date
    @location = location
    @cashier_shifts = cashier_shifts
    @current_cashier = current_cashier
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
      cashier_shifts = @cashier_shifts
      location = @location
      current_cashier = @current_cashier
      current_user = @current_user
      friendly_type_method = method(:friendly_transactable_type)

      global_totals = Hash.new(0)

      pdf.instance_eval do
        text "Reporte Diario de Caja", size: 12, align: :center, style: :bold
        text "Tienda: #{location&.name}", size: 10, align: :center, style: :bold
        text "Caja: #{current_cashier&.name}", size: 10, align: :center, style: :bold
        move_down 10
        text_box "Fecha inicio: #{I18n.localize(start_date, format: "%d/%m/%y")}", size: 9, at: [ 0, cursor ], width: 100
        text_box "Fecha fin: #{I18n.localize(end_date, format: "%d/%m/%y")}", size: 9, at: [ 110, cursor ], width: 100, align: :right
        move_down 15
        stroke_horizontal_rule
        move_down 10

        text "Resumen", size: 10, style: :bold
        move_down 5
        text "Total de Turnos: #{cashier_shifts.count}", size: 8
        move_down 10
        stroke_horizontal_rule
        move_down 10

        cashier_shifts.each do |cashier_shift|
          text_box "Turno de Caja ##{cashier_shift.id}", size: 10, style: :bold, at: [ 0, cursor ], width: 130
          text_box "Hora: #{cashier_shift.created_at.strftime("%H:%M")}", size: 10, at: [ 130, cursor ], width: 80, align: :right
          move_down 15

          cashier_transaction_lines_data = [ [ "Tx", "Hora", "Tipo", "Medio", "Monto" ] ]
          shift_totals = Hash.new(0)

          cashier_shift.cashier_transactions.each do |cashier_transaction|
            cashier_transaction_lines_data << [
              cashier_transaction.id,
              cashier_transaction.created_at.strftime("%H:%M"),
              friendly_type_method.call(cashier_transaction),
              cashier_transaction.payment_method.description,
              sprintf("S/ %.2f", cashier_transaction.amount)
            ]

            shift_totals[cashier_transaction.payment_method.description] += cashier_transaction.amount
            global_totals[cashier_transaction.payment_method.description] += cashier_transaction.amount
          end

          table cashier_transaction_lines_data do
            cells.padding = 2
            cells.borders = []
            cells.size = 7
            columns(0..3).align = :left
            columns(4).align = :right
            self.header = true
            self.column_widths = [ 25, 30, 70, 35, 52 ]
          end

          if cashier_shifts.count > 1
            move_down 10
            text "Totales por medio de pago para este turno:", size: 9, style: :bold
            shift_totals.each do |payment_method, total|
              text "#{payment_method}: S/ #{sprintf("%.2f", total)}", size: 8
            end
          end
          move_down 10
          stroke_horizontal_rule
          move_down 10
        end
        move_down 10
        text "Total: S/ #{sprintf("%.2f", global_totals.values.sum)}", size: 10, style: :bold
        move_down 10
        text "Totales por medio de pago:", size: 10, style: :bold
        move_down 5
        global_totals.each do |payment_method, total|
          text "#{payment_method}: S/ #{sprintf("%.2f", total)}", size: 9
          move_down 5
        end
        # Add seller totals section
        move_down 20
        text "Total de Ventas por Vendedor:", size: 10, style: :bold
        move_down 10

        seller_totals = Commission.joins(:user)
              .where(created_at: start_date..end_date)
              .group("users.id")
              .sum(:sale_amount_cents)
              .transform_values { |cents| cents / 100.0 }  # Convert cents to dollars
              .sort_by { |_, total| -total }

        seller_totals.each do |seller_id, total|
          seller = User.find(seller_id)
          text "#{seller.name}: S/ #{sprintf("%.2f", total)}", size: 9
          move_down 5
        end
        text_box "Reporte generado el: #{I18n.localize(Time.current, format: "%d/%m/%y - %H:%M:%S")}", size: 8, at: [ 0, cursor ], width: 200
        move_down 10
        text_box "por el usuario: #{current_user.email}", size: 8, at: [ 0, cursor ], width: 200
      end
    end
end
