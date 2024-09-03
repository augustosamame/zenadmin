class Tag < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  has_many :taggings, dependent: :destroy
  has_many :products, through: :taggings

  enum :status, { active: 0, inactive: 1 }
  translate_enum :status
end
