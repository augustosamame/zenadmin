# app/models/discount.rb
class Discount < ApplicationRecord
  include TranslateEnum

  enum :status, { active: 0, inactive: 1 }
  translate_enum :status

  enum :discount_type, { type_global: 0, type_group: 1 }
  translate_enum :discount_type

  has_many :discount_filters, dependent: :destroy
  has_many :tags, through: :discount_filters, source: :filterable, source_type: "Tag"

  before_validation :normalize_group_discount_percentage

  validates :name, presence: true
  validates :discount_percentage,
            numericality: { greater_than: 0, less_than_or_equal_to: 100 },
            if: -> { type_global? && discount_percentage.present? }

  validates :discount_fixed_amount,
            numericality: { greater_than: 0 },
            if: -> { type_global? && discount_fixed_amount.present? }

  validates :group_discount_payed_quantity, presence: true, numericality: { greater_than: 0 }, if: :type_group?
  validates :group_discount_free_quantity, presence: true, numericality: { greater_than: 0 }, if: :type_group?
  validate :group_discount_payed_quantity_greater_than_free_quantity, if: :type_group?

  validate :validate_global_discount_type, if: :type_global?


  validates :start_datetime, presence: true
  validates :end_datetime, presence: true
  validate :end_datetime_after_start_datetime

  scope :active, -> { where(status: :active) }
  scope :current, -> { active.where("start_datetime <= ? AND end_datetime >= ?", Time.current, Time.current) }

  def is_current?
    start_datetime <= Time.current && end_datetime >= Time.current
  end

  def self.toggle_status_based_on_datetime
    sleep 5 # to prevent race condition with discount start / end datetime
    Discount.all.each do |discount|
      if discount.start_datetime <= Time.current && discount.end_datetime >= Time.current
        discount.update(status: :active)
      else
        discount.update(status: :inactive)
      end
    end
  end

  def update_matching_product_ids
    matching_products = Product.all

    if discount_filters.where(filterable_type: "Tag").exists?
      tag_ids = discount_filters.where(filterable_type: "Tag").pluck(:filterable_id)
      matching_products = matching_products.joins(:taggings).where(taggings: { tag_id: tag_ids })
    end

    self.update_column(:matching_product_ids, matching_products.distinct.pluck(:id))
  end

  def matching_products
    return Product.none if matching_product_ids.blank?

    Product.includes(:media)
           .where(id: matching_product_ids)
           .order(:name)
  end

  private

  def normalize_group_discount_percentage
    if type_group?
      if group_discount_percentage_off.present?
        if group_discount_percentage_off >= 100
          self.group_discount_percentage_off = nil
        elsif group_discount_percentage_off <= 0
          self.group_discount_percentage_off = nil
        end
      end
    end
  end

  def end_datetime_after_start_datetime
    return if end_datetime.blank? || start_datetime.blank?

    if end_datetime < start_datetime
      errors.add(:end_datetime, "debe ser después de la fecha de inicio")
    end
  end

  def group_discount_payed_quantity_greater_than_free_quantity
    return if group_discount_payed_quantity.blank? || group_discount_free_quantity.blank?

    errors.add(:group_discount_payed_quantity, "debe ser mayor que la cantidad que se paga") if group_discount_payed_quantity <= group_discount_free_quantity
  end

  def validate_global_discount_type
    if discount_percentage.present? && discount_fixed_amount.present?
      errors.add(:base, "Solo puede especificar porcentaje de descuento o monto fijo, no ambos")
    elsif discount_percentage.blank? && discount_fixed_amount.blank?
      errors.add(:base, "Debe especificar porcentaje de descuento o monto fijo")
    end
  end
end
