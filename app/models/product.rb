class Product < ApplicationRecord
  audited_if_enabled

  include PgSearch::Model
  include MediaAttachable

  belongs_to :brand
  belongs_to :sourceable, polymorphic: true, optional: true
  has_and_belongs_to_many :product_categories
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings
  has_many :purchase_lines, class_name: "Purchases::PurchaseLine"
  has_many :warehouse_inventories, dependent: :destroy
  has_many :warehouses, through: :warehouse_inventories

  enum :status, { active: 0, inactive: 1 }

  validates :sku, presence: true
  validates :name, presence: true
  validates :description, presence: true
  validates :permalink, presence: true
  validates :price_cents, presence: true

  monetize :price_cents, with_model_currency: :currency
  monetize :discounted_price_cents, with_model_currency: :currency

  pg_search_scope :search_by_sku_and_name, against: [ :sku, :name ], using: {
      tsearch: { prefix: true }
  }

  before_validation :set_permalink

  def set_permalink
    self.permalink = name.parameterize if permalink.blank?
  end

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

  def stock(warehouse)
    inventory = WarehouseInventory.find_by(warehouse: warehouse, product: self)
    inventory&.stock || 0
  end

  def update_stock(warehouse, quantity)
    inventory = WarehouseInventory.find_or_create_by(warehouse: warehouse, product: self)
    inventory.update(stock: quantity)
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
