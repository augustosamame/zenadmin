class Location < ApplicationRecord
  audited_if_enabled

  include DefaultRegionable

  belongs_to :region
  has_many :warehouses
  has_many :users
end
