class UserAttendanceLog < ApplicationRecord
  include TranslateEnum
  audited_if_enabled
  belongs_to :user
  belongs_to :location

  attr_accessor :captured_photo

  validates :checkin, presence: true
  validate :user_not_checked_in_elsewhere, on: :create

  scope :current, -> { where(checkout: nil) }

  enum :status, [ :active, :inactive ]
  translate_enum :status

  after_commit :update_user_location, if: :should_update_user_location?

  def update_user_location
    latest_log = user.user_attendance_logs.order(checkin: :desc).first

    if self == latest_log
      if self.checkout.present?
        user.update(location_id: nil)
      else
        user.update(location_id: self.location_id)
      end
    end
  end

  def self.checkin(user, location)
    create!(user: user, location: location, checkin: Time.current)
    user.update(last_checkin_at: Time.current, location_id: location.id)
  end

  def self.checkout(user, location)
    current.find_by(user: user, location: location).update(checkout: Time.current)
  end

  private

    def should_update_user_location?
      saved_change_to_checkin? || saved_change_to_checkout?
    end

    def user_not_checked_in_elsewhere
      if user.user_attendance_logs.current.exists?
        errors.add(:base, "El vendedor ya tiene un checkin en otra tienda")
      end
    end
end
