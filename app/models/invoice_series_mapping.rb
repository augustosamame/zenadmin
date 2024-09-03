class InvoiceSeriesMapping < ApplicationRecord
  belongs_to :invoice_series
  belongs_to :location
  belongs_to :payment_method, optional: true

  validates :invoice_series_id, uniqueness: { scope: [ :location_id, :payment_method_id, :comprobante_type ] }
end
