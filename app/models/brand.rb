class Brand < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  has_many :products

  enum :status, { active: 0, inactive: 1 }
  translate_enum :status

  validates :name, presence: true
  validates :name, uniqueness: true
end
