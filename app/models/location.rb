class Location < ApplicationRecord
  include DefaultRegionable

  belongs_to :region
  has_many :warehouses
  has_many :users
end
