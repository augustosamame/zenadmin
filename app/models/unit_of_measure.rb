class UnitOfMeasure < ApplicationRecord
  include TranslateEnum

  belongs_to :reference_unit, class_name: "UnitOfMeasure", optional: true
  has_many :derived_units, class_name: "UnitOfMeasure", foreign_key: :reference_unit_id, dependent: :nullify

  enum :status, { active: 0, inactive: 1 }
  translate_enum :status

  validates :name, presence: true, uniqueness: true
  validates :abbreviation, presence: true
  validates :multiplier, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true

  scope :default_unit, -> { where(default: true).first }

  def to_s
    name
  end
end
