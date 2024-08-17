class ProductCategory < ApplicationRecord
  # Self-referential association for parent-child relationships (subcategories)
  belongs_to :parent, class_name: 'ProductCategory', optional: true
  has_many :subcategories, class_name: 'ProductCategory', foreign_key: 'parent_id', dependent: :destroy

  # Many-to-many relationship with products
  has_and_belongs_to_many :products

  # Validations for the attributes
  validates :name, presence: true

  # Enum for the product category type
  enum :product_category_type, { type_all: 0 }

  # Enum for the status of the product category
  enum :status, { active: 0, inactive: 1 }

  # Method to get the full name of the product category or subcategory
  def full_name
    parent.present? ? "#{parent.full_name} - #{name}" : name
  end
end