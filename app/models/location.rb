class Location < ApplicationRecord
  audited_if_enabled
  include DefaultRegionable
  include TranslateEnum

  belongs_to :region
  has_many :warehouses
  has_many :users
  has_many :cashiers, dependent: :destroy
  has_many :commission_ranges, dependent: :destroy
  has_many :orders
  has_many :user_attendance_logs

  validates :name, presence: true
  validates :email, presence: true

  after_create :create_warehouse_and_cashier

  accepts_nested_attributes_for :commission_ranges, reject_if: :all_blank, allow_destroy: true

  enum :status, [ :active, :inactive ]
  translate_enum :status

  def create_warehouse_and_cashier
    Warehouse.create!(name: "Almacén #{self.name}", location: self)
    Cashier.create!(name: "Caja Ventas #{self.name}", location: self)
    Cashier.create!(name: "Caja Chica #{self.name}", location: self)
  end
end
