class Product < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  include PgSearch::Model
  include MediaAttachable
  include CustomNumberable

  belongs_to :brand
  belongs_to :sourceable, polymorphic: true, optional: true
  has_and_belongs_to_many :product_categories
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings
  has_many :purchase_lines, class_name: "Purchases::PurchaseLine"
  has_many :warehouse_inventories, dependent: :destroy
  has_many :warehouses, through: :warehouse_inventories
  has_many :stock_transfer_lines
  has_many :stock_transfers, through: :stock_transfer_lines
  has_many :order_items
  has_many :orders, through: :order_items
  has_many :preorders
  has_many :combo_products_as_product_1, class_name: "ComboProduct", foreign_key: "product_1_id"
  has_many :combo_products_as_product_2, class_name: "ComboProduct", foreign_key: "product_2_id"


  enum :status, { active: 0, inactive: 1 }
  translate_enum :status

  validates :custom_id, presence: true
  validates :name, presence: true
  validates :description, presence: true
  validates :permalink, presence: true
  validates :price_cents, presence: true

  monetize :price_cents, with_model_currency: :currency
  monetize :discounted_price_cents, with_model_currency: :currency

  pg_search_scope :search_by_custom_id_and_name, against: [ :custom_id, :name ], using: {
      tsearch: { prefix: true, any_word: false }
  }, ignoring: :accents

  scope :tagged_with, ->(tag_name) {
    joins(:tags).where(tags: { name: tag_name })
  }

  scope :without_tests, -> { where(is_test_product: false) }

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

  # Check if the product is tagged with a tag
  def tagged_with?(tag_name_or_object)
    tag = find_or_get_tag(tag_name_or_object)
    self.tags.exists?(tag.id)
  end

  def stock(warehouse)
    inventory = warehouse_inventories.find { |wi| wi.warehouse_id == warehouse.id }
    inventory&.stock || 0
  end

  def update_stock(warehouse, quantity)
    inventory = WarehouseInventory.find_or_create_by(warehouse: warehouse, product: self)
    inventory.update(stock: quantity)
  end

  def smart_image(size)
    self.media&.first&.smart_image(size)
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
