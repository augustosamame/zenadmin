class PaymentMethod < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  enum :status, { active: 0, inactive: 1 }
  translate_enum :status

  enum :payment_method_type, { standard: 0, bank: 1, credit: 2 }
  translate_enum :payment_method_type

  after_create :create_cashier_for_bank_payment_methods

  def create_cashier_for_bank_payment_methods
    location = Location.find_by!(is_main: true)
    if self.payment_method_type == "bank"
      Cashier.find_or_create_by!(name: self.description, location: location, cashier_type: "bank")
    end
  end
end
