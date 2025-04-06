class VoidedOrder < ApplicationRecord
  belongs_to :location
  belongs_to :user

  validates :original_order_id, :original_order_custom_id, :original_order_data, :voided_at, presence: true

  attr_accessible :original_order_id, :original_order_custom_id, :location_id,
                 :user_id, :original_order_data, :voided_at, :void_reason,
                 :invoice_list if respond_to?(:attr_accessible)

  def last_invoice_void_url
    last_invoice_id = invoice_list.split(", ").last
    Invoice.find_by(custom_id: last_invoice_id)&.void_url if last_invoice_id.present?
  end
end
