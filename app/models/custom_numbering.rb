class CustomNumbering < ApplicationRecord
  enum :record_type, { purchases_vendor: 0, supplier: 1, purchase: 2, product: 3, order: 4, cash_inflow: 5, cash_outflow: 6, payment: 7, stock_transfer: 8 }, prefix: :numbering
  enum :status, { active: 0, inactive: 1 }

  validates :record_type, presence: true
  validates :prefix, presence: true
  validates :next_number, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :length, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :prefix, uniqueness: { scope: :record_type }

  after_initialize :set_defaults, if: :new_record?

  def self.for_record_type(record_type, category_prefix = nil)
    if record_type == :product && category_prefix.present?
      find_or_create_by(record_type: record_type, prefix: category_prefix)
    else
      find_or_create_by(record_type: record_type)
    end
  end

  # Convert the model name to the record type taking into account namespaced models
  def self.record_type_for_model(model_name)
    model_name.underscore.gsub("/", "_").to_sym
  end

  private

  def set_defaults
    self.prefix ||= "#{record_type[0, 3].upcase}"
  end
end