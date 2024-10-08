class Supplier < ApplicationRecord
  audited_if_enabled

  include DefaultRegionable
  include CustomNumberable

  belongs_to :region
  belongs_to :sourceable, polymorphic: true
  has_many :products, as: :sourceable
  has_many :purchase_lines, through: :products
  has_many :purchases, through: :purchase_lines
end
