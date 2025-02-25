class Invoice < ApplicationRecord
  belongs_to :order
  belongs_to :invoice_series
  has_one :invoicer, through: :invoice_series
  belongs_to :payment_method

  enum :sunat_status, { sunat_pending: 0, sunat_success: 1, sunat_error: 2, application_error: 3 }
  enum :status, { pending: 0, issued: 1, voided: 2 }
  enum :invoice_type, { boleta: 0, factura: 1, nota_credito: 2, nota_debito: 3, anulacion_boleta: 4, anulacion_factura: 5, anulacion_nota_credito: 6, anulacion_nota_debito: 7 }

  monetize :amount_cents, with_model_currency: :currency

  after_create :increment_next_number

  private

    def increment_next_number
      invoice_series.increment!(:next_number) unless sunat_status == "application_error" || sunat_status == "sunat_error"
    end
end
