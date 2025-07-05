class CustomNumbering < ApplicationRecord
  include TranslateEnum

  enum :record_type, {
    purchases_vendor: 0,
    supplier: 1,
    purchase: 2,
    product: 3,
    order: 4,
    cash_inflow: 5,
    cash_outflow: 6,
    payment: 7,
    stock_transfer: 8,
    requisition: 9,
    planned_stock_transfer: 10,
    purchases_purchase_order: 11,
    purchases_purchase: 12,
    purchase_payment: 13
  }, prefix: :numbering
  enum :status, { active: 0, inactive: 1 }
  translate_enum :status

  validates :record_type, presence: true
  validates :prefix, presence: true
  validates :next_number, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :length, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :prefix, uniqueness: { scope: :record_type }

  after_initialize :set_defaults, if: :new_record?

  def self.for_record_type(record_type, category_prefix = nil)
    # Ensure record_type is valid
    unless record_types.key?(record_type.to_s)
      Rails.logger.warn("Invalid record_type: #{record_type} for CustomNumbering")
      # Return a default CustomNumbering with a generic prefix to avoid errors
      return new(record_type: record_types.keys.first, prefix: record_type.to_s[0, 3].upcase, next_number: 1, length: 5)
    end
    
    # Create with explicit prefix to avoid validation errors
    prefix = if record_type == :product && category_prefix.present?
               category_prefix
             else
               record_type.to_s[0, 3].upcase
             end
    
    find_or_create_by!(record_type: record_type, prefix: prefix)
  end

  # Convert the model name to the record type taking into account namespaced models
  def self.record_type_for_model(model_name)
    # Special case for Purchases::Purchase to maintain compatibility with existing records
    return :purchase if model_name == "Purchases::Purchase"
    
    model_name.underscore.gsub("/", "_").to_sym
  end

  private

  def set_defaults
    # Make sure record_type is a string before trying to use it
    if record_type.present?
      # Convert symbol to string if needed
      rt = record_type.is_a?(Symbol) ? record_type.to_s : record_type
      self.prefix ||= rt[0, 3].upcase
    else
      # Fallback prefix if record_type is not set yet
      self.prefix ||= "UNK"
    end
  end
end
