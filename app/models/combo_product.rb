class ComboProduct < ApplicationRecord
  belongs_to :product_1, class_name: "Product"
  belongs_to :product_2, class_name: "Product"

  monetize :price_cents, with_model_currency: :currency
  monetize :normal_price_cents, with_model_currency: :currency

  enum :status, { active: 0, inactive: 1 }

  before_validation :set_currency

  validates :product_1, presence: true
  validates :qty_1, presence: true
  validates :product_2, presence: true
  validates :qty_2, presence: true

  validate :product_1_and_product_2_are_different
  validate :discounted_price_is_less_than_normal_price

  def set_currency
    self.currency = "PEN"
  end

  def stock(warehouse_id)
    [ self.product_1.stock(warehouse_id) / qty_1,
     self.product_2.stock(warehouse_id) / qty_2 ].min
  end

  def product_1_and_product_2_are_different
    if product_1 == product_2
      errors.add(:product_1, "los productos del combo no pueden ser los mismos")
    end
  end

  def discounted_price_is_less_than_normal_price
    if price > normal_price
      errors.add(:price, "El precio descontado no puede ser mayor que el precio normal")
    end
  end
end
