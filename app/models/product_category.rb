class ProductCategory < ApplicationRecord
  audited_if_enabled

  include MediaAttachable
  include TranslateEnum

  # Self-referential association for parent-child relationships (subcategories)
  belongs_to :parent, class_name: "ProductCategory", optional: true
  has_many :subcategories, class_name: "ProductCategory", foreign_key: "parent_id", dependent: :destroy

  # Many-to-many relationship with products
  has_and_belongs_to_many :products

  # Validations for the attributes
  validates :name, presence: true

  # Enum for the product category type
  enum :product_category_type, { type_all: 0 }

  # Enum for the status of the product category
  enum :status, { active: 0, inactive: 1 }
  translate_enum :status

  after_commit :create_or_update_tag, on: [ :create, :update ]

  def full_name
    self.parent.present? ? "#{self.parent.full_name} - #{self.name}" : self.name
  end

  private

    def create_or_update_tag
      tag = Tag.find_or_create_by(name: name)
      tag.update(name: self.name) if tag.name != self.name
    end
end
