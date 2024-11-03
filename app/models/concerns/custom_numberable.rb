# app/models/concerns/custom_numberable.rb
module CustomNumberable
  extend ActiveSupport::Concern

  included do
    before_validation :set_custom_id, on: :create
  end

  private

  def set_custom_id
    return if self.custom_id.present?
    # Get the record type dynamically from the model class name
    record_type = CustomNumbering.record_type_for_model(self.class.name)

    if record_type == :product && self.product_categories.present?
      product_category_name = self.product_categories&.first&.name
      category_prefix = "#{product_category_name[0..3].upcase}"
      config = CustomNumbering.for_record_type(record_type, category_prefix)
    else
      config = CustomNumbering.for_record_type(record_type)
    end

    # Dynamically determine the column name for the custom ID
    custom_id_column = self.class.custom_id_column
    self[custom_id_column] = "#{config.prefix}#{config.next_number.to_s.rjust(config.length, '0')}"

    # Increment the next_number for the next record
    config.increment!(:next_number)
  end

  class_methods do
    def custom_id_column
      "custom_id"
    end
  end
end
