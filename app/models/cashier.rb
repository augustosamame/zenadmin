class Cashier < ApplicationRecord
  include TranslateEnum

  belongs_to :location
  has_many :cashier_shifts
  has_many :cashier_transactions, through: :cashier_shifts

  enum :status, { active: 0, inactive: 1 }
  translate_enum :status

  def old_current_shift(current_user)
    open_shift = cashier_shifts.find_or_initialize_by(status: :open)
    if open_shift.new_record?
      open_shift.assign_attributes(
        date: Date.current,
        opened_at: Time.current,
        opened_by_id: current_user.id,
        total_sales_cents: 0
      )
      open_shift.save
    end
    open_shift
  end

  def current_shift(current_user)
    cashier_shifts.last
  end
end
