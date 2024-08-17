class Purchases::Purchase < ApplicationRecord
  belongs_to :vendor, class_name: 'Purchases::Vendor'
  has_many :purchase_lines, class_name: 'Purchases::PurchaseLine', dependent: :destroy

  accepts_nested_attributes_for :purchase_lines
end
