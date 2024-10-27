class ProductPackItem < ApplicationRecord
  belongs_to :product_pack
  has_and_belongs_to_many :tags

  validates :quantity, presence: true, numericality: { greater_than: 0 }
end
