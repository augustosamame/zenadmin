class Product < ApplicationRecord
  belongs_to :brand
  belongs_to :sourceable, polymorphic: true, optional: true
  has_and_belongs_to_many :product_categories
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings
  has_many :purchase_lines, class_name: 'Purchases::PurchaseLine'

  def add_tag(tag_name_or_object)
    tag = find_or_get_tag(tag_name_or_object)

    if tag
      unless self.tags.exists?(tag.id)
        self.tags << tag
      end
    else
      raise ActiveRecord::RecordNotFound, "Tag with name '#{tag_name_or_object}' not found"
    end
  end

  private

  def find_or_get_tag(tag_name_or_object)
    if tag_name_or_object.is_a?(Tag)
      tag_name_or_object
    elsif tag_name_or_object.is_a?(String)
      Tag.find_by(name: tag_name_or_object)
    end
  end
end
