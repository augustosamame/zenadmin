module Factory
  class Factory < ApplicationRecord
    include DefaultRegionable
    
    belongs_to :region
    has_many :products, as: :sourceable
    has_many :warehouses
  end
end
