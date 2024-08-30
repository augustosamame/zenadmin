module Purchases
  class Vendor < ApplicationRecord
    include DefaultRegionable
    include CustomNumberable

    belongs_to :region
    has_many :products, as: :sourceable
  end
end
