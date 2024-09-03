class Invoicer < ApplicationRecord
  audited_if_enabled
  include DefaultRegionable

  belongs_to :region
  has_many :invoice_series
  has_many :invoice_series_mappings, through: :invoice_series
  has_many :locations, through: :invoice_series_mappings

  validates :name, presence: true, uniqueness: true
  validates :default, uniqueness: true, if: :default?

  scope :default, -> { find_by(default: true) }

  enum :tipo_ruc, { RUC: 1, RUS: 2 }
  enum :einvoice_integrator, { nubefact: 0 }
  enum :status, { active: 0, inactive: 1 }
end
