class Admin::ExternalInvoicesController < Admin::AdminController
  def new
    @order = Order.find(params[:order_id])
    @external_invoice = @order.external_invoices.build

    respond_to do |format|
      format.html do
        if request.xhr?
          render partial: "form", locals: { order: @order, external_invoice: @external_invoice }, layout: false
        else
          render :new
        end
      end
    end
  end

  def create
    @order = Order.find(params[:order_id])

    # First try to find an existing invoice
    existing_invoice = Invoice.find_by(custom_id: external_invoice_params[:custom_id])

    if existing_invoice
      # Link existing invoice to order
      @order.invoices << existing_invoice
      redirect_to admin_order_path(@order), notice: "Comprobante vinculado exitosamente."
    else
      # Create new external invoice
      @external_invoice = @order.external_invoices.build(external_invoice_params)
      @external_invoice.amount_cents = @order.total_price_cents
      @external_invoice.currency = @order.currency

      if @external_invoice.save
        redirect_to admin_order_path(@order), notice: "Comprobante externo creado exitosamente."
      else
        respond_to do |format|
          format.html do
            render partial: "form",
              locals: { order: @order, external_invoice: @external_invoice },
              status: :unprocessable_entity,
              layout: false
          end
        end
      end
    end
  end

  def destroy
    @order = Order.find(params[:order_id])

    begin
      @external_invoice = @order.external_invoices.find(params[:id])

      if @external_invoice.destroy
        flash[:notice] = "Comprobante eliminado exitosamente."
      else
        flash[:alert] = "No se pudo eliminar el comprobante."
      end
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "Comprobante eliminado exitosamente."
    end

    # Determine redirect path based on referrer
    redirect_path = if request.referrer&.include?("/orders/#{@order.id}")
      admin_order_path(@order)
    else
      admin_orders_path
    end

    respond_to do |format|
      format.html do
        render inline: %(
          <script>
            window.flash = #{flash.to_json.html_safe};
            window.location.replace('#{redirect_path}');
          </script>
        ), content_type: "text/html"
      end
      format.turbo_stream do
        render inline: %(
          <script>
            window.flash = #{flash.to_json.html_safe};
            window.location.replace('#{redirect_path}');
          </script>
        ), content_type: "text/html"
      end
    end
  end

  private

  def external_invoice_params
    params.require(:external_invoice).permit(:custom_id, :invoice_type, :invoice_url)
  end
end
