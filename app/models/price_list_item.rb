class PriceListItem < ApplicationRecord
  belongs_to :price_list
  belongs_to :product

  monetize :price_cents, with_model_currency: :currency
  
  validates :product_id, uniqueness: { scope: :price_list_id, message: "already has a price in this price list" }
  
  before_validation :set_currency
  
  # Virtual attribute to handle price as float
  def price=(value)
    self.price_cents = (value.to_f * 100).to_i
  end
  
  private
  
  def set_currency
    self.currency ||= product&.currency
  end
end
