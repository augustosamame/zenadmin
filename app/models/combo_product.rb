class ComboProduct < ApplicationRecord
  belongs_to :product_1, class_name: "Product"
  belongs_to :product_2, class_name: "Product"

  monetize :price_cents, with_model_currency: :currency
  monetize :normal_price_cents, with_model_currency: :currency
end
