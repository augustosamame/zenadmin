# app/models/user.rb
class User < ApplicationRecord
  has_person_name
  has_one_attached :avatar
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  before_validation :set_login

  # Validations for email and phone number
  validates :email, presence: true, if: -> { login_type == "email" }
  validates :phone, presence: true, if: -> { login_type == "phone" }
  validates :login, presence: true, uniqueness: true

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    where(conditions.to_h).where([ "login = :value", { value: login } ]).first
  end

  private

  def set_login
    self.login = self.email if login_type == "email"
    self.login = self.phone if login_type == "phone"
  end

  def login_type
    # Replace this with your actual global setting logic
    # For example, it could be an environment variable or a value stored in the database
    # Setting.find_by(name: "login_type").get_value || "email"
    Rails.application.config.global_settings[:login_type]
  end
end
