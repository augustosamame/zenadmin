class Order < ApplicationRecord
  include DefaultRegionable
  
  belongs_to :region
  belongs_to :user
  belongs_to :location
end
