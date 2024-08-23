class Warehouse < ApplicationRecord
  audited_if_enabled

  include DefaultRegionable

  belongs_to :region
end
