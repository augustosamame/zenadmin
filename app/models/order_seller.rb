class OrderSeller < ApplicationRecord
  audited_if_enabled

  belongs_to :order
  belongs_to :user
end
