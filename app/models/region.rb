class Region < ApplicationRecord
  has_many :locations
  has_many :orders
  has_many :suppliers
  has_many :purchases, class_name: "Purchases::Purchase"
  has_many :vendors, class_name: "Purchases::Vendor"
  has_many :warehouses
  has_many :factories

  validates :name, presence: true
  validates :name, uniqueness: true

  def self.default
    # Check if multi_region is false
    multi_region_setting = Setting.find_by(name: 'multi_region')
    
    if multi_region_setting && !multi_region_setting.boolean_value
      # Find or create the default region
      find_or_create_by(name: 'default')
    else
      nil
    end
  end
end
