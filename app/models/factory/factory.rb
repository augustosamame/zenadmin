module Factory
  class Factory < ApplicationRecord
    # If the FactorySupplier model has any relationships, such as products it supplies, you would define them here.

    # For example, if FactorySupplier can supply many products:
    has_many :products, as: :sourceable

    # You can add any validations, scopes, or methods that are relevant to FactorySupplier here.
  end
end