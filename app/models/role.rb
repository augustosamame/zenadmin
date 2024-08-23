class Role < ApplicationRecord
  audited_if_enabled

  has_many :user_roles
  has_many :users, through: :user_roles
end
