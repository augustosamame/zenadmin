class Admin::InvoiceSeriesController < Admin::AdminController
  before_action :set_invoice_series, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize! :read, InvoiceSeries
    @invoice_series = InvoiceSeries.all
  end

  def show
    authorize! :read, @invoice_series
  end

  def new
    authorize! :create, InvoiceSeries
    @invoice_series = InvoiceSeries.new
  end

  def create
    authorize! :create, InvoiceSeries
    @invoice_series = InvoiceSeries.new(invoice_series_params)
    if @invoice_series.save
      redirect_to admin_invoice_series_index_path, notice: "Invoice series was successfully created."
    else
      render :new
    end
  end

  def edit
    authorize! :update, @invoice_series
  end

  def update
    authorize! :update, @invoice_series
    if @invoice_series.update(invoice_series_params)
      redirect_to admin_invoice_series_index_path, notice: "Invoice series was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    authorize! :destroy, @invoice_series
    @invoice_series.destroy
    redirect_to admin_invoice_series_index_path, notice: "Invoice series was successfully destroyed."
  end

  private

  def set_invoice_series
    @invoice_series = InvoiceSeries.find(params[:id])
  end

  def invoice_series_params
    params.require(:invoice_series).permit(:invoicer_id, :comprobante_type, :prefix, :next_number, :status, :comments)
  end
end
