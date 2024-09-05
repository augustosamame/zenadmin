class InvoiceSeries < ApplicationRecord
  belongs_to :invoicer
  has_many :locations, through: :invoice_series_mappings
  has_many :invoices

  validates :prefix, presence: true
  validates :next_number, presence: true, numericality: { greater_than_or_equal_to: 1 }

  enum :status, { active: 0, inactive: 1 }
  enum :comprobante_type, { boleta: 0, factura: 1, nota_credito: 2, nota_debito: 3 }

  def next_invoice_number
    "#{prefix}-#{next_number.to_s.rjust(6, '0')}"
  end
end
