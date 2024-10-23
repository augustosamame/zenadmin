class DiscountFilter < ApplicationRecord
  belongs_to :discount
  belongs_to :filterable, polymorphic: true
end
