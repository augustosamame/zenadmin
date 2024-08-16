# app/models/user.rb
class User < ApplicationRecord
  has_person_name
  has_one_attached :avatar
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  attr_writer :login

  # Validations for email and phone number
  validates :email, presence: true, if: -> { login_type == "email" }
  validates :phone, presence: true, if: -> { login_type == "phone" }
  validates :login, presence: true, uniqueness: true

  # Add a custom method to determine the login type
  def login
    @login || self.email || self.phone
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    where(conditions.to_h).where([ "login = :value", { value: login } ]).first
  end

  private

  def login_type
    # Replace this with your actual global setting logic
    # For example, it could be an environment variable or a value stored in the database
    Setting.login_type || "email"
  end
end
