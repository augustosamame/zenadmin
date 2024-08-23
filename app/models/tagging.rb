class Tagging < ApplicationRecord
  audited_if_enabled

  belongs_to :tag
  belongs_to :product

  validates :tag_id, uniqueness: { scope: :product_id }
end
