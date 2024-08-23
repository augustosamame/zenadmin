class PaymentMethod < ApplicationRecord
  audited_if_enabled

  enum :status, { active: 0, inactive: 1 }
end
