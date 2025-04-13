class Admin::PurchaseInvoicesController < Admin::AdminController
  include MoneyRails::ActionViewExtension
  include CurrencyFormattable
  include AdminHelper

  before_action :set_purchase_invoice, only: [ :show, :edit, :update, :destroy ]

  def index
    respond_to do |format|
      format.html do
        @purchase_invoices = PurchaseInvoice.includes(:vendor, :purchase).order(created_at: :desc).limit(10)
        @datatable_options = "server_side:true;resource_name:'PurchaseInvoice';sort_0_desc;hide_0;create_button:true;"
      end

      format.json do
        render json: datatable_json
      end
    end
  end

  def new
    @purchase_invoice = PurchaseInvoice.new
  end

  def create
    @purchase_invoice = PurchaseInvoice.new(purchase_invoice_params)

    respond_to do |format|
      if @purchase_invoice.save
        format.html { redirect_to admin_purchase_invoice_path(@purchase_invoice), notice: "Comprobante de compra creado exitosamente." }
        format.json { render :show, status: :created, location: @purchase_invoice }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @purchase_invoice.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
  end

  def edit
  end

  def update
    respond_to do |format|
      if @purchase_invoice.update(purchase_invoice_params)
        format.html { redirect_to admin_purchase_invoice_path(@purchase_invoice), notice: "Comprobante de compra actualizado exitosamente." }
        format.json { render :show, status: :ok, location: @purchase_invoice }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @purchase_invoice.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @purchase_invoice.destroy
    respond_to do |format|
      format.html { redirect_to admin_purchase_invoices_path, notice: "Comprobante de compra eliminado exitosamente." }
      format.json { head :no_content }
    end
  end

  private

  def set_purchase_invoice
    @purchase_invoice = PurchaseInvoice.find(params[:id])
  end

  def purchase_invoice_params
    params.require(:purchase_invoice).permit(
      :purchase_id,
      :vendor_id,
      :purchase_invoice_date,
      :purchase_invoice_type,
      :custom_id,
      :amount,
      :currency,
      :payment_status,
      :planned_payment_date
    )
  end

  def datatable_json
    search_value = params[:search][:value] if params[:search].present?

    purchase_invoices = PurchaseInvoice.includes(:purchase, :vendor)

    # Apply search if provided
    if search_value.present?
      purchase_invoices = purchase_invoices.where(
        "purchase_invoices.custom_id ILIKE :search OR
         purchase_invoices.currency ILIKE :search OR
         purchases_vendors.name ILIKE :search",
        search: "%#{search_value}%"
      ).joins(:vendor)
    end

    # Apply sorting
    if params[:order].present?
      order_column = params[:order]["0"][:column].to_i
      direction = params[:order]["0"][:dir] == "asc" ? :asc : :desc

      case order_column
      when 1
        purchase_invoices = purchase_invoices.order(purchase_id: direction)
      when 2
        purchase_invoices = purchase_invoices.joins(:vendor).order("purchases_vendors.name #{direction}")
      when 3
        purchase_invoices = purchase_invoices.order(purchase_invoice_date: direction)
      when 4
        purchase_invoices = purchase_invoices.order(purchase_invoice_type: direction)
      when 5
        purchase_invoices = purchase_invoices.order(custom_id: direction)
      when 6
        purchase_invoices = purchase_invoices.order(amount_cents: direction)
      when 7
        purchase_invoices = purchase_invoices.order(payment_status: direction)
      when 8
        purchase_invoices = purchase_invoices.order(planned_payment_date: direction)
      else
        purchase_invoices = purchase_invoices.order(created_at: :desc)
      end
    else
      purchase_invoices = purchase_invoices.order(created_at: :desc)
    end

    # Pagination
    purchase_invoices = purchase_invoices.page(params[:start].to_i / params[:length].to_i + 1).per(params[:length].to_i)

    {
      draw: params[:draw].to_i,
      recordsTotal: PurchaseInvoice.count,
      recordsFiltered: search_value.present? ? purchase_invoices.total_count : PurchaseInvoice.count,
      data: purchase_invoices.map do |invoice|
        [
          invoice.id,
          invoice.purchase&.custom_id || "-",
          invoice.vendor&.name || "-",
          invoice.purchase_invoice_date&.strftime("%d/%m/%Y") || "-",
          invoice.description == "Saldo inicial" ? "Saldo inicial" : invoice.translated_purchase_invoice_type,
          invoice.custom_id,
          humanized_money_with_symbol(invoice.amount),
          payment_status_badge(invoice.payment_status),
          invoice.planned_payment_date&.strftime("%d/%m/%Y") || "-",
          render_to_string(
            partial: "admin/purchase_invoices/actions",
            formats: [ :html ],
            locals: { purchase_invoice: invoice }
          )
        ]
      end
    }
  end

  def payment_status_badge(status)
    case status
    when "pending"
      "<span class='px-2 py-1 text-xs font-semibold text-yellow-800 bg-yellow-100 rounded-full'>Pendiente</span>"
    when "partially_paid"
      "<span class='px-2 py-1 text-xs font-semibold text-blue-800 bg-blue-100 rounded-full'>Pago Parcial</span>"
    when "paid"
      "<span class='px-2 py-1 text-xs font-semibold text-green-800 bg-green-100 rounded-full'>Pagado</span>"
    when "void"
      "<span class='px-2 py-1 text-xs font-semibold text-red-800 bg-red-100 rounded-full'>Anulado</span>"
    else
      status
    end
  end
end
