class Purchases::PurchaseLine < ApplicationRecord
  belongs_to :purchase, class_name: 'Purchases::Purchase'
  belongs_to :product

  # You can access the supplier through the product:
  delegate :sourceable, to: :product, prefix: true
end
