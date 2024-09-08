class Warehouse < ApplicationRecord
  audited_if_enabled

  include DefaultRegionable

  belongs_to :region
  belongs_to :location, optional: true

  has_many :warehouse_inventories, dependent: :destroy
  has_many :products, through: :warehouse_inventories
  has_many :preorders, dependent: :destroy

  scope :main_warehouse, -> { where(is_main: true).first }
end
