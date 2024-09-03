class Admin::InvoiceSeriesMappingsController < Admin::AdminController
  before_action :set_invoice_series_mapping, only: [ :show, :edit, :update, :destroy ]

  def index
    @invoice_series_mappings = InvoiceSeriesMapping.all
  end

  def show
  end

  def new
    @invoice_series_mapping = InvoiceSeriesMapping.new
    @locations = Location.active
    @invoicers = Invoicer.active
    @payment_methods = PaymentMethod.active
  end

  def create
    @invoice_series_mapping = InvoiceSeriesMapping.new(invoice_series_mapping_params)
    if @invoice_series_mapping.save
      redirect_to admin_invoice_series_mapping_path(@invoice_series_mapping), notice: "Invoice series mapping was successfully created."
    else
      render :new
    end
  end

  def edit
    @locations = Location.active
    @invoicers = Invoicer.active
    @payment_methods = PaymentMethod.active
  end

  def update
    if @invoice_series_mapping.update(invoice_series_mapping_params)
      redirect_to admin_invoice_series_mapping_path(@invoice_series_mapping), notice: "Invoice series mapping was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @invoice_series_mapping.destroy
    redirect_to admin_invoice_series_mappings_path, notice: "Invoice series mapping was successfully destroyed."
  end

  private

  def set_invoice_series_mapping
    @invoice_series_mapping = InvoiceSeriesMapping.find(params[:id])
  end

  def invoice_series_mapping_params
    params.require(:invoice_series_mapping).permit(:invoice_series_id, :location_id, :payment_method_id)
  end
end
