module Purchases
  class Vendor < ApplicationRecord
    include DefaultRegionable
    include CustomNumberable

    belongs_to :region
    has_many :products, as: :sourceable
    has_many :purchase_orders, class_name: 'Purchases::PurchaseOrder', foreign_key: 'vendor_id'
  end
end
