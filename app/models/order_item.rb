class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  monetize :price_cents, with_model_currency: :currency
end
