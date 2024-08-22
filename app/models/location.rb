class Location < ApplicationRecord
  include DefaultRegionable

  belongs_to :region
  has_many :warehouses

end
