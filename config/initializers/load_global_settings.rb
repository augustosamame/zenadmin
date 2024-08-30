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
    :stock_transfers_have_in_transit_step,
    :show_sunat_guia_for_stock_transfers
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

  def check_custom_numberings
    return unless ActiveRecord::Base.connection.table_exists?("custom_numberings")

    CustomNumbering.record_types.keys.each do |record_type|
      unless CustomNumbering.exists?(record_type: record_type)
        case record_type
        when 'purchases_vendor'
          CustomNumbering.find_or_create_by!(record_type: :purchases_vendor, prefix: 'VEN', length: 5, next_number: 1, status: :active)
        when 'supplier'
          CustomNumbering.find_or_create_by!(record_type: :supplier, prefix: 'SUP', length: 5, next_number: 1, status: :active)
        when 'purchase'
          CustomNumbering.find_or_create_by!(record_type: :purchase, prefix: 'PUR', length: 5, next_number: 1, status: :active)
        when 'product'
          CustomNumbering.find_or_create_by!(record_type: :product, prefix: 'PRO', length: 5, next_number: 1, status: :active)
        when 'order'
          CustomNumbering.find_or_create_by!(record_type: :order, prefix: 'ORD', length: 5, next_number: 1, status: :active)
        when 'cash_inflow'
          CustomNumbering.find_or_create_by!(record_type: :cash_inflow, prefix: 'CIN', length: 5, next_number: 1, status: :active)
        when 'cash_outflow'
          CustomNumbering.find_or_create_by!(record_type: :cash_outflow, prefix: 'COU', length: 5, next_number: 1, status: :active)
        when 'payment'
          CustomNumbering.find_or_create_by!(record_type: :payment, prefix: 'PAY', length: 5, next_number: 1, status: :active)
        when 'stock_transfer'
          CustomNumbering.find_or_create_by!(record_type: :stock_transfer, prefix: 'INT', length: 5, next_number: 1, status: :active)
        else
          raise "CustomNumbering for #{record_type} not found"
        end
      end
    end
  end

  begin
    load_global_settings
    check_custom_numberings
  rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad => e
    Rails.logger.warn "Database not available: #{e.message}. Skipping global settings load."
  end
end
