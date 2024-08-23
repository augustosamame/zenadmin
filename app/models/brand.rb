class Brand < ApplicationRecord
  audited_if_enabled

  has_many :products

  enum status: { active: 0, inactive: 1 }

  validates :name, presence: true
  validates :name, uniqueness: true
end
