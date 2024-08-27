# config/initializers/load_global_settings.rb
$global_settings = {}

Rails.application.config.after_initialize do
  REQUIRED_SETTINGS = [
    :login_type,
    :admin_2fa_required,
    :track_inventory,
    :multi_region,
    :max_price_discount_percentage,
    :ecommerce_active,
    :pos_can_create_unpaid_orders,
    :audited_active,
    :negative_stocks_allowed,
    :stock_transfers_have_in_transit_step
  ]

  def load_global_settings
    return unless ActiveRecord::Base.connection.table_exists?("settings")

    settings = Setting.all.each_with_object({}) do |setting, hash|
      hash[setting.name.to_sym] = setting.get_value
    end

    missing_settings = REQUIRED_SETTINGS.select { |key| settings[key].nil? }

    if missing_settings.any?
      Rails.logger.debug "Missing required settings: #{missing_settings.join(', ')}"
      puts "Missing required settings: #{missing_settings.join(', ')}"
    end

    $global_settings.merge!(settings)
  end

  begin
    load_global_settings
  rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad => e
    Rails.logger.warn "Database not available: #{e.message}. Skipping global settings load."
  end
end
