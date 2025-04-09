class Purchases::PurchaseOrder < ApplicationRecord
  include DefaultRegionable
  include CustomNumberable
  include TranslateEnum

  belongs_to :region
  belongs_to :user
  belongs_to :vendor, class_name: "Purchases::Vendor"
  belongs_to :transportista, optional: true
  has_many :purchase_order_lines, class_name: "Purchases::PurchaseOrderLine", dependent: :destroy
  has_one :purchase, class_name: "Purchases::Purchase"

  enum :status, { draft: 0, pending: 1, approved: 2, partially_received: 3, received: 4, cancelled: 5 }
  translate_enum :status

  accepts_nested_attributes_for :purchase_order_lines, allow_destroy: true

  validates :order_date, presence: true
  validates :vendor_id, presence: true

  def self.custom_id_column
    "custom_id"
  end

  def translated_status
    case status
    when "draft"
      "Borrador"
    when "pending"
      "Pendiente"
    when "approved"
      "Aprobada"
    when "partially_received"
      "Parcialmente Recibida"
    when "received"
      "Recibida"
    when "cancelled"
      "Cancelada"
    else
      status.humanize
    end
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
        purchase_order: self,
        purchase_date: Date.current,
        transportista_id: transportista_id
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
