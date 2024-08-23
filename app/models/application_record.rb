class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.audited_if_enabled
    if $global_settings[:audited_active]
      audited
    end
  end
end
