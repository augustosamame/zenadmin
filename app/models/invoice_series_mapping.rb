class InvoiceSeriesMapping < ApplicationRecord
  belongs_to :invoice_series
  belongs_to :location
  belongs_to :payment_method, optional: true

  validate :unique_mapping_per_comprobante_type

  attr_accessor :invoicer_id

  # This is used to set the invoicer_id based on the invoice_series_id for edit form
  def invoicer_id
    @invoicer_id ||= invoice_series&.invoicer_id
  end

  private

  def unique_mapping_per_comprobante_type
    existing_mapping = InvoiceSeriesMapping.joins(:invoice_series)
      .where(location_id: location_id, payment_method_id: payment_method_id)
      .where.not(id: id)
      .where(invoice_series: { comprobante_type: invoice_series&.comprobante_type })
      .exists?

    if existing_mapping
      errors.add(:base, "Ya existe un mapeo para esta ubicación, método de pago y tipo de comprobante")
    end
  end
end
