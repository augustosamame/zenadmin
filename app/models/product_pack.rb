class ProductPack < ApplicationRecord
  include TranslateEnum

  has_many :product_pack_items, dependent: :destroy
  has_many :tags, through: :product_pack_items

  enum :status, { active: 0, inactive: 1 }
  translate_enum :status

  monetize :price_cents, with_model_currency: :currency

  validates :name, presence: true
  validates :price_cents, presence: true, numericality: { greater_than: 0 }
  validates :start_datetime, presence: true
  validates :end_datetime, presence: true
  validate :end_datetime_after_start_datetime

  scope :active, -> { where(status: :active) }
  scope :current, -> { active.where("start_datetime <= ? AND end_datetime >= ?", Time.current, Time.current) }

  accepts_nested_attributes_for :product_pack_items, allow_destroy: true, reject_if: :all_blank

  def is_current?
    start_datetime <= Time.current && end_datetime >= Time.current
  end


  def self.toggle_status_based_on_datetime
    sleep 5 # to prevent race condition with product_pack start / end datetime
    ProductPack.all.each do |product_pack|
      if product_pack.start_datetime <= Time.current && product_pack.end_datetime >= Time.current
        product_pack.update(status: :active)
      else
        product_pack.update(status: :inactive)
      end
    end
  end

  def end_datetime_after_start_datetime
    return if end_datetime.blank? || start_datetime.blank?

    if end_datetime < start_datetime
      errors.add(:end_datetime, "debe ser después de la fecha de inicio")
    end
  end
end
