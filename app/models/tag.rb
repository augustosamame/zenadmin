class Tag < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  has_many :taggings, dependent: :destroy
  has_many :products, through: :taggings

  has_and_belongs_to_many :product_pack_items

  enum :status, { active: 0, inactive: 1 }
  translate_enum :status

  enum :tag_type, { other: 0, discount: 1, category: 2, sub_category: 3, volume: 4, fragance: 5 }
  translate_enum :tag_type
end
