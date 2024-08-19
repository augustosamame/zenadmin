class Warehouse < ApplicationRecord
  include DefaultRegionable

  belongs_to :region
end
