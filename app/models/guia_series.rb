# app/models/guia_series.rb
class GuiaSeries < ApplicationRecord
  belongs_to :invoicer
  has_many :guias

  enum :guia_type, { guia_remision: 0, guia_transportista: 1 }

  validates :prefix, presence: true
  validates :next_number, presence: true
  validates :guia_type, presence: true

  def next_invoice_number
    "#{prefix}-#{next_number.to_s.rjust(8, '0')}"
  end
end
