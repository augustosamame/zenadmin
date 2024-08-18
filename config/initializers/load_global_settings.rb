Rails.application.config.after_initialize do
  REQUIRED_SETTINGS = [:login_type, :admin_2fa_required, :track_inventory, :multi_region]

  def load_global_settings
    return unless ActiveRecord::Base.connection.table_exists?('settings') # Skip if settings table doesn't exist

    settings = Setting.all.each_with_object({}) do |setting, hash|
      hash[setting.name.to_sym] = setting.get_value
    end

    # Check for required settings
    missing_settings = REQUIRED_SETTINGS.select { |key| settings[key].nil? }

    if missing_settings.any?
      Rails.logger.debug "Missing required settings: #{missing_settings.join(', ')}"
      puts "Missing required settings: #{missing_settings.join(', ')}"
    end

    Rails.application.config.global_settings = settings
  end

  # Load settings at startup
  load_global_settings
end