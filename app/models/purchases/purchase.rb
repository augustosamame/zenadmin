class Purchases::Purchase < ApplicationRecord
  include DefaultRegionable
  include CustomNumberable

  belongs_to :region
  belongs_to :user
  belongs_to :vendor, class_name: "Purchases::Vendor"
  belongs_to :purchase_order, class_name: "Purchases::PurchaseOrder", optional: true
  belongs_to :transportista, optional: true
  has_many :purchase_lines, class_name: "Purchases::PurchaseLine", dependent: :destroy

  accepts_nested_attributes_for :purchase_lines, allow_destroy: true
  
  validates :purchase_date, presence: true
  validates :vendor_id, presence: true
  
  def self.custom_id_column
    "purchase_number"
  end
  
  def total_amount
    purchase_lines.sum(&:total_price)
  end
end
