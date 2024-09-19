class LoyaltyTier < ApplicationRecord
  has_many :users
  has_many :user_free_products
  belongs_to :free_product, class_name: "Product", optional: true

  enum :status, { active: 0, inactive: 1 }

  validates :name, presence: true, uniqueness: true
  validate :discount_or_free_product
  validate :requirements_orders_count_and_total_amount

  def discount_or_free_product
    unless discount_percentage_integer.present? || free_product_id.present?
      errors.add(:base, "Debes ingresar un descuento o un producto gratis")
    end
  end

  def requirements_orders_count_and_total_amount
    unless requirements_orders_count.present? || requirements_total_amount.present?
      errors.add(:base, "Debes ingresar una cantidad de compras o un monto total")
    end
  end

  def discount_percentage_integer
    (discount_percentage * 100).to_i if discount_percentage
  end

  def discount_percentage_integer=(value)
    if value.blank?
      self.discount_percentage = nil
    else
      self.discount_percentage = value.to_f / 100
    end
  end
end
