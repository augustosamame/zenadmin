class ExternalInvoice < ApplicationRecord
  belongs_to :order

  enum :sunat_status, { sunat_pending: 0, sunat_success: 1, sunat_error: 2, application_error: 3 }
  enum :status, { pending: 0, issued: 1, voided: 2 }
  enum :invoice_type, { boleta: 0, factura: 1, nota_credito: 2, nota_debito: 3, anulacion_boleta: 4, anulacion_factura: 5, anulacion_nota_credito: 6, anulacion_nota_debito: 7 }

  monetize :amount_cents, with_model_currency: :currency

  validates :custom_id, presence: true, uniqueness: { scope: :invoice_type }
end
