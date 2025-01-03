class Admin::InvoicersController < Admin::AdminController
  before_action :set_invoicer, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize! :read, Invoicer
    @invoicers = Invoicer.all.order(id: :asc)
  end

  def show
    authorize! :read, @invoicer
  end

  def new
    authorize! :create, Invoicer
    @invoicer = Invoicer.new
  end

  def create
    @invoicer = Invoicer.new(invoicer_params)
    if @invoicer.save
      redirect_to admin_invoicers_path, notice: "Invoicer was successfully created."
    else
      render :new
    end
  end

  def edit
    authorize! :update, @invoicer
  end

  def update
    if @invoicer.update(invoicer_params)
      redirect_to admin_invoicers_path, notice: "Invoicer was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    authorize! :destroy, @invoicer
    @invoicer.destroy
    redirect_to admin_invoicers_path, notice: "Invoicer was successfully destroyed."
  end

  def invoice_series
    authorize! :read, Invoicer
    @invoicer = Invoicer.find(params[:id])
    render json: @invoicer.invoice_series.map { |series| { id: series.id, prefix: series.prefix } }
  end

  private

  def set_invoicer
    @invoicer = Invoicer.find(params[:id])
  end

  def invoicer_params
    params.require(:invoicer).permit(:region_id, :name, :razon_social, :ruc, :tipo_ruc, :einvoice_integrator, :einvoice_url, :einvoice_api_key, :einvoice_api_secret, :default, :status)
  end
end
