class Location < ApplicationRecord
  include DefaultRegionable
  
  belongs_to :region
  has_many :warehouses

  before_validation :assign_default_region, on: :create
end
