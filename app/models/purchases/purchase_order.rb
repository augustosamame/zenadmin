class Purchases::PurchaseOrder < ApplicationRecord
  include DefaultRegionable
  include CustomNumberable

  belongs_to :region
  belongs_to :user
  belongs_to :vendor, class_name: "Purchases::Vendor"
  has_many :purchase_order_lines, class_name: "Purchases::PurchaseOrderLine", dependent: :destroy
  has_one :purchase, class_name: "Purchases::Purchase"

  enum :status, { draft: 0, submitted: 1, partially_received: 2, received: 3, cancelled: 4 }

  accepts_nested_attributes_for :purchase_order_lines, allow_destroy: true

  validates :order_date, presence: true
  validates :vendor_id, presence: true

  def self.custom_id_column
    "purchase_order_number"
  end

  def total_amount
    purchase_order_lines.sum(&:total_price)
  end

  def create_purchase
    return if purchase.present?

    Purchase.transaction do
      new_purchase = Purchases::Purchase.create!(
        region_id: region_id,
        user_id: user_id,
        vendor_id: vendor_id,
        purchase_date: Date.current,
        purchase_order: self
      )

      purchase_order_lines.each do |po_line|
        new_purchase.purchase_lines.create!(
          product_id: po_line.product_id,
          quantity: po_line.quantity,
          unit_price: po_line.unit_price
        )
      end

      # Update purchase order status
      update(status: :received)

      # Update inventory
      Services::Inventory::PurchaseItemService.new(new_purchase).update_inventory

      new_purchase
    end
  end
end
