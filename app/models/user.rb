# app/models/user.rb
class User < ApplicationRecord
  has_person_name
  has_one_attached :avatar
  has_many :user_roles
  has_many :roles, through: :user_roles
  has_one :customer, dependent: :destroy
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Validations for email and phone number
  validates :email, presence: true, if: -> { login_type == "email" }
  validates :phone, presence: true, if: -> { login_type == "phone" }
  validates :login, presence: true, uniqueness: true

  scope :with_role, ->(role_name) { joins(:roles).where(roles: { name: role_name }) }

  before_validation :set_login
  after_save :ensure_customer_created

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    where(conditions.to_h).where([ "login = :value", { value: login } ]).first
  end

  def name
    "#{first_name} #{last_name}"
  end

  def ensure_customer_created
    if roles.exists?(name: "customer") && customer.nil?
      create_customer
    end
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
