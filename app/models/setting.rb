class Setting < ApplicationRecord
  audited

  enum status: { active: 0, inactive: 1 }

  validates :name, presence: true, uniqueness: true
  validates :localized_name, presence: true, uniqueness: true

  enum data_type: { type_string: 0, type_integer: 1, type_float: 2, type_datetime: 3, type_boolean: 4, type_hash: 5 }

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
end
