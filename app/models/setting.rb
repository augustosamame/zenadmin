class Setting < ApplicationRecord
  audited_if_enabled

  enum :status, { active: 0, inactive: 1 }

  validates :name, presence: true, uniqueness: true
  validates :localized_name, presence: true

  validate :unique_active_settings

  enum :data_type, { type_string: 0, type_integer: 1, type_float: 2, type_datetime: 3, type_boolean: 4, type_hash: 5 }

  def get_value
    case data_type
    when "type_string"
      string_value
    when "type_integer"
      integer_value
    when "type_float"
      float_value
    when "type_datetime"
      datetime_value
    when "type_boolean"
      boolean_value
    when "type_hash"
      hash_value
    else
      string_value
    end
  end

  private

  def unique_active_settings
    return unless active?

    # Check for duplicate name
    duplicate_name = Setting.active.where(name: name).where.not(id: id).first
    if duplicate_name
      errors.add(:name, "ya está en uso por otro setting activo: #{duplicate_name.attributes.inspect}")
    end

    # Check for duplicate localized_name
    duplicate_localized = Setting.active.where(localized_name: localized_name).where.not(id: id).first
    if duplicate_localized
      errors.add(:localized_name, "ya está en uso por otro setting activo: #{duplicate_localized.attributes.inspect}")
    end
  end
end
