# app/models/user.rb
class User < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  # has_person_name
  has_one_attached :avatar
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_one :customer, dependent: :destroy
  has_one :user_seller_photo, dependent: :destroy
  has_many :commissions, dependent: :destroy
  has_many :commissioned_orders, through: :commissions, source: :order
  belongs_to :location, optional: true
  belongs_to :loyalty_tier, optional: true
  has_many :user_free_products
  has_many :orders
  has_many :user_attendance_logs

  # Monetize the account_receivable_initial_balance field
  monetize :account_receivable_initial_balance_cents

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :status, { active: 0, inactive: 1 }
  translate_enum :status
  # Validations for email and phone number
  validates :email, presence: true, if: -> { login_type == "email" }
  validates :phone, presence: true, if: -> { login_type == "phone" }
  validates :login, presence: true, uniqueness: true

  scope :with_role, ->(role_name) { joins(:roles).where(roles: { name: role_name }) }
  scope :with_any_role, ->(*role_names) { joins(:roles).where(roles: { name: role_names }).distinct }

  accepts_nested_attributes_for :customer, allow_destroy: true
  accepts_nested_attributes_for :user_seller_photo, allow_destroy: true

  before_validation :set_login
  before_validation :set_user_email, on: :create

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    where(conditions.to_h).where([ "login = :value", { value: login } ]).first
  end

  def name
    "#{first_name} #{last_name}"
  end

  def address
    self.customer&.wants_factura? ? self&.customer&.factura_direccion : self&.customer&.dni_address
  end

  def set_user_email
    if self.customer.present? && login_type == "email"
      if self.customer.doc_id.present?
        generated_email = "#{self.customer.doc_id}@sincorreo.com"
      elsif self.customer.factura_ruc.present?
        generated_email = "#{self.customer.factura_ruc}@sincorreo.com"
      else
        generated_email = "#{rand(10000000)}@sincorreo.com"
      end
      self.email = generated_email
      self.login = generated_email
    end
  end

  def add_role(role_name)
    role = Role.find_by(name: role_name)
    unless self.roles.include?(role)
      self.roles << role
    end
  end

  def has_role?(role_name)
    self.roles.where(name: role_name).any?
  end

  def has_any_role?(*role_names)
    self.roles.where(name: role_names).any?
  end

  def self.first_admin_or_superadmin_user
    User.joins(:roles).where(roles: { name: [ "admin", "super_admin" ] }).first
  end

  def any_admin?
    self.roles.where(name: [ "admin", "super_admin" ]).any?
  end

  def any_admin_or_supervisor?
    self.roles.where(name: [ "admin", "super_admin", "supervisor" ]).any?
  end

  def any_admin_or_warehouse_manager?
    self.roles.where(name: [ "admin", "super_admin", "warehouse_manager" ]).any?
  end

  def store_or_store_manager?
    self.roles.where(name: [ "store_manager", "store" ]).any?
  end

  def roles_names
    self.roles.pluck(:name).join(", ")
  end

  def total_order_amount
    Money.new(total_order_amount_cents || 0, "PEN") # Replace 'PEN' with your default currency if different
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
    $global_settings[:login_type]
  end
end
