class ProductPack < ApplicationRecord
  include TranslateEnum

  has_many :product_pack_items, dependent: :destroy
  has_many :tags, through: :product_pack_items

  enum :status, { active: 0, inactive: 1 }
  translate_enum :status

  monetize :price_cents, with_model_currency: :currency

  validates :name, presence: true
  validates :price_cents, presence: true, numericality: { greater_than: 0 }

  accepts_nested_attributes_for :product_pack_items, allow_destroy: true, reject_if: :all_blank
end
