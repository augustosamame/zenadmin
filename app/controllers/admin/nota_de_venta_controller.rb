class Admin::NotaDeVentaController < Admin::AdminController
  before_action :set_order

  def show
    respond_to do |format|
      format.pdf do
        pdf_content = generate_nota_de_venta
        filename = "nota_de_venta_#{@order.custom_id}.pdf"
        
        send_data pdf_content,
                  filename: filename,
                  type: "application/pdf",
                  disposition: "inline",
                  stream: "true",
                  buffer_size: "4096"
      end
      format.html { redirect_to admin_order_path(@order) }
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def generate_nota_de_venta
    NotaDeVenta.new(@order, current_user).render
  end
end
