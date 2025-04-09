module CustomNumberable
  extend ActiveSupport::Concern

  included do
    before_validation :set_custom_id, on: :create
  end

  private

  def set_custom_id
    # Dynamically determine the column name for the custom ID
    custom_id_column = self.class.custom_id_column
    
    # Return if the custom ID is already set
    return if self[custom_id_column].present?
    
    # Get the record type dynamically from the model class name
    record_type = CustomNumbering.record_type_for_model(self.class.name)
    
    # Find or create the custom numbering configuration
    if record_type == :product && self.product_categories.present?
      product_category_name = self.product_categories&.first&.name
      category_prefix = "#{product_category_name[0..3].upcase}"
      config = CustomNumbering.for_record_type(record_type, category_prefix)
    else
      config = CustomNumbering.for_record_type(record_type)
    end
    
    # Set the custom ID using the determined column
    self[custom_id_column] = "#{config.prefix}#{config.next_number.to_s.rjust(config.length, '0')}"
    
    # Increment the next_number for the next record - use update_column to bypass callbacks
    # This ensures the next_number is updated even if there are validation errors
    config.update_column(:next_number, config.next_number + 1)
  end

  class_methods do
    def custom_id_column
      "custom_id"
    end
  end
end
