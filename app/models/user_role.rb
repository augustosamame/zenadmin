class UserRole < ApplicationRecord
  audited_if_enabled

  belongs_to :user
  belongs_to :role

  validates :user_id, uniqueness: { scope: :role_id, message: "can only have one of each role" }
end
