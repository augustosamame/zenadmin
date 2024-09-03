module DefaultRegionable
  extend ActiveSupport::Concern

  included do
    before_validation :assign_default_region, on: :create
  end

  private

  def assign_default_region
    if !$global_settings[:multi_region]
      self.region ||= Region.default
    else
      # Handle cases where multi-region is true, or provide a fallback
    end
  rescue
    # If something goes wrong, log the error and handle it gracefully
    Rails.logger.warn "Default region could not be assigned. Ensure regions are seeded correctly."
  end
end
