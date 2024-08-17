module Purchases
  class Vendor < ApplicationRecord
    
    has_many :products, as: :sourceable

  end
end