class PaymentMethod < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  enum :status, { active: 0, inactive: 1 }
  translate_enum :status
end
