module Purchases
  audited_if_enabled

  def self.table_name_prefix
    "purchases_"
  end
end
