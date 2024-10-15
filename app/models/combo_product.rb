class ComboProduct < ApplicationRecord
  belongs_to :product_1, class_name: "Product"
  belongs_to :product_2, class_name: "Product"

  monetize :price_cents, with_model_currency: :currency
  monetize :normal_price_cents, with_model_currency: :currency

  enum :status, { active: 0, inactive: 1 }

  before_validation :set_currency

  def set_currency
    self.currency = "PEN"
  end
end
