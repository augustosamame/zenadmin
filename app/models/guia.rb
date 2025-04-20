# app/models/guia.rb
class Guia < ApplicationRecord
  include TranslateEnum
  self.table_name = "guias"

  belongs_to :stock_transfer, optional: true
  belongs_to :order, optional: true
  belongs_to :guia_series
  has_one :invoicer, through: :guia_series

  enum :sunat_status, { sunat_pending: 0, sunat_success: 1, sunat_error: 2, application_error: 3 }
  translate_enum :sunat_status
  enum :status, { pending: 0, issued: 1, voided: 2 }
  translate_enum :status
  enum :guia_type, { guia_remision: 0, guia_transportista: 1 }
  translate_enum :guia_type

  after_create :increment_next_number

  private

  def increment_next_number
    guia_series.increment!(:next_number) unless sunat_status == "application_error"
  end
end
