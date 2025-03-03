class PriceList < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  has_many :price_list_items, dependent: :destroy
  has_many :products, through: :price_list_items
  has_many :customers

  enum :status, { active: 0, inactive: 1 }
  translate_enum :status

  validates :name, presence: true, uniqueness: true
  
  scope :active_lists, -> { where(status: :active) }
  
  def product_price(product)
    price_list_item = price_list_items.find_by(product_id: product.id)
    price_list_item&.price || product.price
  end
end
