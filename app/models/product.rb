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
  has_many :product_min_max_stocks, dependent: :destroy
  has_many :requisition_lines
  has_many :requisitions, through: :requisition_lines
  has_many :price_list_items, dependent: :destroy
  has_many :price_lists, through: :price_list_items

  accepts_nested_attributes_for :price_list_items

  enum :status, { active: 0, inactive: 1 }
  translate_enum :status

  validates :custom_id, presence: true
  validates :name, presence: true
  validates :description, presence: true
  validates :permalink, presence: true
  validates :price_cents, presence: true
  validates :flat_commission_percentage, numericality: { greater_than: 0 }, if: :flat_commission?

  monetize :price_cents, with_model_currency: :currency
  monetize :discounted_price_cents, with_model_currency: :currency

  before_validation :set_discounted_price

  def set_discounted_price
    # we do this now as discounts are handled through time sensitive discount objects or price lists
    self.discounted_price_cents = price_cents
  end

  def currency
    "PEN"  # Default currency code for Peruvian Sol
  end

  pg_search_scope :search_by_custom_id_and_name, against: [ :custom_id, :name ], using: {
      tsearch: { prefix: true, any_word: false }
  }, ignoring: :accents

  scope :tagged_with, ->(tag_name) {
    joins(:tags).where(tags: { name: tag_name })
  }

  def self.tagged_with(tags)
    joins(:taggings)
      .where(taggings: { tag_id: tags.map(&:id) })
      .distinct
  end

  scope :without_tests, -> { where(is_test_product: false) }

  before_validation :set_permalink
  after_commit :create_warehouse_inventory_for_all_warehouses, on: :create
  after_commit :create_price_list_items_for_all_price_lists, on: :create, if: -> { $global_settings[:feature_flag_price_lists] }

  def set_permalink
    self.permalink = name.parameterize if permalink.blank?
  end

  def create_warehouse_inventory_for_all_warehouses
    Warehouse.all.each do |warehouse|
      WarehouseInventory.create(warehouse: warehouse, product: self, stock: 0)
    end
  end

  def create_price_list_items_for_all_price_lists
    PriceList.active_lists.each do |price_list|
      PriceListItem.create(price_list: price_list, product: self, price: self.price)
    end
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
    image_media = self.media.find_by(media_type: "image")
    default_media = self.media.find_by(media_type: "default_image")
    
    (image_media || default_media)&.smart_image(size)
  end

  def price_for_customer(customer)
    return self.price unless $global_settings[:feature_flag_price_lists]

    if customer&.price_list
      price_list_item = price_list_items.find_by(price_list_id: customer.price_list_id)
      return price_list_item.price if price_list_item
    end

    self.price
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
