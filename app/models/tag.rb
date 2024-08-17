class Tag < ApplicationRecord
  has_many :taggings, dependent: :destroy
  has_many :products, through: :taggings

  enum :status, { active: 0, inactive: 1 }
end
