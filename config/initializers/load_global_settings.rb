# config/initializers/load_global_settings.rb
$global_settings = {}

Rails.application.config.after_initialize do
  REQUIRED_SETTINGS = [
    { name: :login_type, default: "email", data_type: "type_string", localized_name: "Tipo de Login", internal: true },
    { name: :admin_2fa_required, default: false, data_type: "type_boolean", localized_name: "Autenticación de 2 factores requerido para admin", internal: false },
    { name: :track_inventory, default: true, data_type: "type_boolean", localized_name: "Medición de Inventarios", internal: true },
    { name: :multi_region, default: false, data_type: "type_boolean", localized_name: "Gestión de Múltiples Regiones", internal: true },
    { name: :max_price_discount_percentage, default: 10, data_type: "type_integer", localized_name: "Max % de descuento", internal: false },
    { name: :max_total_sale_without_customer, default: 700, data_type: "type_integer", localized_name: "Maximo total de venta sin cliente", internal: false },
    { name: :ecommerce_active, default: true, data_type: "type_boolean", localized_name: "Módulo Ecommerce Activo", internal: true },
    { name: :pos_can_create_unpaid_orders, default: false, data_type: "type_boolean", localized_name: "POS puede crear ventas impagas", internal: true },
    { name: :audited_active, default: true, data_type: "type_boolean", localized_name: "Se generan tablas de auditoría", internal: true },
    { name: :negative_stocks_allowed, default: true, data_type: "type_boolean", localized_name: "Se permiten stocks negativos", internal: true },
    { name: :stock_transfers_have_in_transit_step, default: true, data_type: "type_boolean", localized_name: "Las transferencias de stock tienen un paso intermedio En Tránsito", internal: true },
    { name: :feature_flag_purchases, default: false, data_type: "type_boolean", localized_name: "Módulo de compras activo", internal: false },
    { name: :show_sunat_guia_for_stock_transfers, default: false, data_type: "type_boolean", localized_name: "Mostrar guías de remisión SUNAT en transferencias de stock", internal: true },
    { name: :logo_path, default: "logo_jardin_del_zen.png", data_type: "type_string", localized_name: "Ruta del logo", internal: false },
    { name: :feature_flag_notas_de_venta, default: false, data_type: "type_boolean", localized_name: "Permite generar notas de venta", internal: false },
    { name: :linked_cashiers_for_payment_methods, default: false, data_type: "type_boolean", localized_name: "Cada método de pago depositará en su propia caja", internal: false },
    { name: :address_for_dni, default: false, data_type: "type_boolean", localized_name: "Se mostrará y enviará a SUNAT dirección para boletas", internal: false },
    { name: :feature_flag_sellers_can_void_orders, default: false, data_type: "type_boolean", localized_name: "Vendedores pueden anular órdenes", internal: false },
    { name: :feature_flag_sellers_products_can_have_flat_commissions, default: false, data_type: "type_boolean", localized_name: "Productos pueden tener comision plana", internal: false }
  ]

  def load_global_settings
    return unless ActiveRecord::Base.connection.table_exists?("settings")

    REQUIRED_SETTINGS.each do |setting|
      Setting.find_or_create_by!(name: setting[:name]) do |s|
        s.data_type = setting[:data_type]
        s.localized_name = setting[:localized_name]
        s.internal = setting[:internal]
        s.send("#{setting[:data_type].split('_').last}_value=", setting[:default])
      end
    end

    $global_settings = Setting.all.index_by { |setting| setting.name.to_sym }.transform_values(&:get_value)
  end

  def check_custom_numberings
    return unless ActiveRecord::Base.connection.table_exists?("custom_numberings")

    # Load settings first to ensure $global_settings is populated
    load_global_settings if $global_settings.empty?

    # Get all record types
    all_record_types = CustomNumbering.record_types.keys

    # Identify purchase-related record types
    purchase_related_types = all_record_types.select do |record_type|
      record_type.start_with?("purchases_") ||
      record_type == "purchase" ||
      record_type == "purchase_payment"
    end

    # Filter out purchase-related record types if the feature flag is disabled
    record_types_to_check = if $global_settings[:feature_flag_purchases] == false
      all_record_types - purchase_related_types
    else
      all_record_types
    end

    # Define default configurations for each record type
    default_configs = {
      "purchases_vendor" => { prefix: "VEP", length: 4 },
      "supplier" => { prefix: "PRO", length: 4 },
      "purchase" => { prefix: "COM", length: 5 },
      "purchases_purchase" => { prefix: "COM", length: 5 },
      "product" => { prefix: "PRO", length: 4 },
      "order" => { prefix: "VEN", length: 6 },
      "cash_inflow" => { prefix: "CIN", length: 5 },
      "cash_outflow" => { prefix: "COU", length: 5 },
      "payment" => { prefix: "PAG", length: 6 },
      "stock_transfer" => { prefix: "INT", length: 5 },
      "requisition" => { prefix: "PED", length: 5 },
      "planned_stock_transfer" => { prefix: "PLA", length: 5 },
      "purchases_purchase_order" => { prefix: "POO", length: 6 },
      "purchase_payment" => { prefix: "PPR", length: 6 }
    }

    record_types_to_check.each do |record_type|
      unless CustomNumbering.exists?(record_type: record_type)
        # Get default config or use a generic one
        config = default_configs[record_type] || { prefix: record_type[0, 3].upcase, length: 5 }

        begin
          # Create the CustomNumbering record with the appropriate configuration
          CustomNumbering.create!(
            record_type: record_type,
            prefix: config[:prefix],
            length: config[:length],
            next_number: 1,
            status: :active
          )
        rescue => e
          # Log the error but don't raise it during initialization
          # This prevents the app from crashing during startup
          Rails.logger.error("Error creating CustomNumbering for #{record_type}: #{e.message}")

          # Only raise for non-purchase related record types if feature flag is enabled
          is_purchase_related = record_type.start_with?("purchases_") ||
                              record_type == "purchase" ||
                              record_type == "purchase_payment"

          if !is_purchase_related || $global_settings[:feature_flag_purchases]
            raise e
          end
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
