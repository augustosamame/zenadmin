class Tag < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  belongs_to :parent_tag, class_name: "Tag", optional: true
  has_many :children_tags, class_name: "Tag", foreign_key: :parent_tag_id, dependent: :nullify

  has_many :taggings, dependent: :destroy
  has_many :products, through: :taggings

  has_and_belongs_to_many :product_pack_items

  enum :status, { active: 0, inactive: 1 }
  translate_enum :status

  enum :tag_type, { other: 0, discount: 1, category: 2, sub_category: 3, capacity: 4, weight: 5, fragance: 6 }
  translate_enum :tag_type

  validate :parent_child_relationship_valid

  def root_tag?
    parent_tag.nil?
  end

  private

  def parent_child_relationship_valid
    return unless parent_tag_id.present?

    unless [ "category", "sub_category" ].include?(tag_type)
      errors.add(:parent_tag_id, "only category and sub-category tags can have parent-child relationships")
    end

    if parent_tag_id == id
      errors.add(:parent_tag_id, "cannot be self-referential")
    end
  end
end
