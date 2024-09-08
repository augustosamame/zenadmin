class Preorder < ApplicationRecord
  belongs_to :product
  belongs_to :order
  belongs_to :warehouse

  enum :status, [ :pending, :fulfilled ]
end
