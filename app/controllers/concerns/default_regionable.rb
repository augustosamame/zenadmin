module DefaultRegionable
  extend ActiveSupport::Concern

  included do
    before_validation :assign_default_region, on: :create
  end

  private

  def assign_default_region
    self.region ||= Region.default
  end
end