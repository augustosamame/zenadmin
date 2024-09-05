class OrderItem < ApplicationRecord
  audited_if_enabled

  belongs_to :order
  belongs_to :product

  monetize :price_cents, with_model_currency: :currency
  monetize :discounted_price_cents, with_model_currency: :currency
end
