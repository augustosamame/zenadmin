# app/models/guia_series.rb
class GuiaSeries < ApplicationRecord
  include TranslateEnum

  belongs_to :invoicer
  has_many :locations, through: :guia_series_mappings
  has_many :guias

  enum :guia_type, { guia_remision: 0, guia_transportista: 1 }
  translate_enum :guia_type

  validates :prefix, presence: true
  validates :next_number, presence: true, numericality: { greater_than_or_equal_to: 1 }
  validates :guia_type, presence: true

  def next_invoice_number
    "#{prefix}-#{next_number.to_s.rjust(8, '0')}"
  end
end
