# app/models/guia.rb
class Guia < ApplicationRecord
  belongs_to :stock_transfer
  belongs_to :guia_series
  has_one :invoicer, through: :guia_series

  enum :sunat_status, { sunat_pending: 0, sunat_success: 1, sunat_error: 2, application_error: 3 }
  enum :status, { pending: 0, issued: 1, voided: 2 }
  enum :guia_type, { guia_remision: 0, guia_transportista: 1 }

  after_create :increment_next_number

  private

  def increment_next_number
    guia_series.increment!(:next_number) unless sunat_status == "application_error"
  end
end
