class Brand < ApplicationRecord
  has_many :products

  enum status: { active: 0, inactive: 1 }

  validates :name, presence: true
  validates :name, uniqueness: true
end
