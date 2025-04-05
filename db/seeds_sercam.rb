puts "Creating settings..."

settings = [
  { name: 'login_type', data_type: 'type_string', internal: true, localized_name: 'Tipo de Login', string_value: 'email', integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: nil, hash_value: nil, status: 'active' },
  { name: 'track_inventory', data_type: 'type_boolean', internal: true, localized_name: 'Medición de Inventarios', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: true, hash_value: nil, status: 'active' },
  { name: 'admin_2fa_required', data_type: 'type_boolean', internal: false, localized_name: 'Autenticación de 2 factores requerido para admin', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: false, hash_value: nil, status: 'active' },
  { name: 'multi_region', data_type: 'type_boolean', internal: true, localized_name: 'Gestión de Múltiples Regiones', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: false, hash_value: nil, status: 'active' },
  { name: 'max_price_discount_percentage', data_type: 'type_integer', internal: false, localized_name: 'Max % de descuento', string_value: nil, integer_value: 10, float_value: nil, datetime_value: nil, boolean_value: nil, hash_value: nil, status: 'active' },
  { name: 'ecommerce_active', data_type: 'type_boolean', internal: true, localized_name: 'Módulo Ecommerce Activo', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: false, hash_value: nil, status: 'active' },
  { name: 'pos_can_create_unpaid_orders', data_type: 'type_boolean', internal: true, localized_name: 'POS puede crear ventas impagas', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: true, hash_value: nil, status: 'active' },
  { name: 'pos_can_create_orders_without_stock_transfers', data_type: 'type_boolean', internal: true, localized_name: 'POS puede crear ventas sin transferencias de stocks', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: true, hash_value: nil, status: 'active' },
  { name: 'audited_active', data_type: 'type_boolean', internal: true, localized_name: 'Se generan tablas de auditoría', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: true, hash_value: nil, status: 'active' },
  { name: 'negative_stocks_allowed', data_type: 'type_boolean', internal: true, localized_name: 'Se permiten stocks negativos', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: true, hash_value: nil, status: 'active' },
  { name: 'stock_transfers_have_in_transit_step', data_type: 'type_boolean', internal: true, localized_name: 'Las transferencias de stock tienen un paso intermedio En Tránsito', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: true, hash_value: nil, status: 'active' },
  { name: 'show_sunat_guia_for_stock_transfers', data_type: 'type_boolean', internal: true, localized_name: 'Mostrar guías de remisión SUNAT en transferencias de stock', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: true, hash_value: nil, status: 'active' },
  { name: 'multiple_invoicers_based_on_location', data_type: 'type_boolean', internal: true, localized_name: 'Múltiples razones sociales por tienda', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: true, hash_value: nil, status: 'active' },
  { name: 'multiple_invoicers_based_on_location_and_payment_method', data_type: 'type_boolean', internal: true, localized_name: 'Múltiples razones sociales por tienda y por medio de pago', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: false, hash_value: nil, status: 'active' },
  { name: 'max_total_sale_without_customer', data_type: 'type_integer', internal: false, localized_name: 'Maximo total de venta sin cliente', string_value: nil, integer_value: 700, float_value: nil, datetime_value: nil, boolean_value: nil, hash_value: nil, status: 'active' },
  { name: 'feature_flag_sales_attributed_to_seller', data_type: 'type_boolean', internal: false, localized_name: 'Ventas comisionables por vendedor', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: false, hash_value: nil, status: 'active' },
  { name: 'feature_flag_seller_checkin', data_type: 'type_boolean', internal: false, localized_name: 'Registro de asistencia de vendedores', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: false, hash_value: nil, status: 'active' },
  { name: 'feature_flag_commission_ranges', data_type: 'type_boolean', internal: false, localized_name: 'Comisiones por rango de ventas', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: false, hash_value: nil, status: 'active' },
  { name: 'feature_flag_loyalty_program', data_type: 'type_boolean', internal: false, localized_name: 'Programa de fidelidad', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: false, hash_value: nil, status: 'active' },
  { name: 'multiple_cashiers_per_location', data_type: 'type_boolean', internal: false, localized_name: 'Múltiples cajeros por ubicación', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: false, hash_value: nil, status: 'active' },
  { name: 'feature_flag_purchases', data_type: 'type_boolean', internal: false, localized_name: 'Módulo de compras activo', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: true, hash_value: nil, status: 'active' },
  { name: 'logo_path', data_type: 'type_string', internal: false, localized_name: 'Ruta del logo', string_value: "logo_grupo_sercam.png", integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: nil, hash_value: nil, status: 'active' },
  { name: 'feature_flag_discounts', data_type: 'type_boolean', internal: false, localized_name: 'Módulo de descuentos activo', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: false, hash_value: nil, status: 'active' },
  { name: 'feature_flag_product_packs', data_type: 'type_boolean', internal: false, localized_name: 'Módulo de paquetes de productos activo', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: false, hash_value: nil, status: 'active' },
  { name: 'feature_flag_birthday_discount', data_type: 'type_boolean', internal: false, localized_name: 'Descuento cumpleañero Activo', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: false, hash_value: nil, status: 'active' },
  { name: 'birthday_discount_percentage', data_type: 'type_integer', internal: false, localized_name: '% de descuento cumpleañero', string_value: nil, integer_value: 0, float_value: nil, datetime_value: nil, boolean_value: true, hash_value: nil, status: 'active' },
  { name: 'default_credit_receivable_due_date', data_type: 'type_integer', internal: false, localized_name: 'Días por defecto para vencimiento de pagos al crédito', string_value: nil, integer_value: 30, float_value: nil, datetime_value: nil, boolean_value: true, hash_value: nil, status: 'active' },
  { name: 'feature_flag_bank_cashiers_active', data_type: 'type_boolean', internal: false, localized_name: 'Cajas tipo banco activos', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: true, hash_value: nil, status: 'active' },
  { name: 'feature_flag_price_lists', data_type: 'type_boolean', internal: false, localized_name: 'Módulo de listas de precios activo', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: true, hash_value: nil, status: 'active' },
  { name: 'feature_flag_notas_de_venta', data_type: 'type_boolean', internal: false, localized_name: 'Permite generar notas de venta', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: true, hash_value: nil, status: 'active' },
  { name: 'linked_cashiers_for_payment_methods', data_type: 'type_boolean', internal: false, localized_name: 'Cada método de pago depositará en su propia caja', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: true, hash_value: nil, status: 'active' }
]

begin
  Setting.upsert_all(
    settings,
    unique_by: [ :name ],
    returning: false
  )
  puts "Settings created successfully!"
rescue StandardError => e
  puts "Error creating settings: #{e.message}"
  raise e
end

Role.find_or_create_by!(name: 'super_admin')
Role.find_or_create_by!(name: 'admin')
Role.find_or_create_by!(name: 'seller')
Role.find_or_create_by!(name: 'supervisor')
Role.find_or_create_by!(name: 'store_manager')
Role.find_or_create_by!(name: 'store')
Role.find_or_create_by!(name: 'warehouse_manager')
Role.find_or_create_by!(name: 'customer')

## custom numbering fields creation now handled by load_global_settings.rb initializer

region_default = Region.find_or_create_by!(name: 'default')

brand_1 = Brand.find_or_create_by!(name: 'Sercam')
brand_2 = Brand.find_or_create_by!(name: 'Otros')


vendor_1 = Purchases::Vendor.find_or_create_by!(name: 'Cementos Sol', region: region_default)
vendor_2 = Purchases::Vendor.find_or_create_by!(name: 'Aceros Arequipa', region: region_default)
factory_1 = Factory::Factory.find_or_create_by!(name: 'Main Factory', region: region_default)

supplier_1 = Supplier.create!(name: "Cementos Sol Vendor", sourceable: vendor_1, region: region_default)
supplier_2 = Supplier.create!(name: "Main Factory", sourceable: factory_1, region: region_default)

# warehouse_user_1 = User.create!(email: 'almacen_principal@sercamsrl.com', phone: "986976311", login: "almacen_principal@sercamsrl.com", require_password_change: false, password: "12345678", first_name: "Almacén", last_name: "Principal", internal: true)
# warehouse_user_1.add_role('warehouse_manager')

# location_0 = Location.find_or_create_by!(name: 'Oficina Principal', region: region_default, email: "oficina@sercamsrl.com", address: 'Av Confraternidad 786, Andahuaylas', phone: '900000000')

# warehouse_0 = Warehouse.find_by!(name: "Almacén Oficina Principal").update(is_main: true)

location_1 = Location.find_or_create_by!(name: 'Talavera', region: region_default, email: "talavera@sercamsrl.com", address: 'Av. Perú 150, Andahuaylas, Apurímac', phone: '900000000', is_main: true)

cashier_main = Cashier.find_or_create_by!(name: "Caja Oficina Principal", location_id: location_1.id, cashier_type: "bank")

location_2 = Location.find_or_create_by!(name: 'Eternit', region: region_default, email: "eternit@sercamsrl.com", address: 'Av. Perú 150, Andahuaylas, Apurímac', phone: '900000009')

location_3 = Location.find_or_create_by!(name: 'Agricultor', region: region_default, email: "agricultor@sercamsrl.com", address: 'Av. Perú 150, Andahuaylas, Apurímac', phone: '900000008')

location_4 = Location.find_or_create_by!(name: 'Transporte', region: region_default, email: "transporte@sercamsrl.com", address: 'Av. Perú 150, Andahuaylas, Apurímac', phone: '900000007')

storeuser1 = User.create!(email: 'talavera@sercamsrl.com', phone: "986976311", location_id: location_1.id, login: "talavera@sercamsrl.com", require_password_change: false, password: "12345678", first_name: "Tienda", last_name: "Talavera", internal: true)
storeuser1.add_role('store')

storeuser2 = User.create!(email: 'eternit@sercamsrl.com', phone: "986976312", location_id: location_2.id, login: "eternit@sercamsrl.com", require_password_change: false, password: "12345678", first_name: "Tienda", last_name: "Eternit", internal: true)
storeuser2.add_role('store')

storeuser3 = User.create!(email: 'agricultor@sercamsrl.com', phone: "928855854", location_id: location_3.id, login: "agricultor@sercamsrl.com", require_password_change: false, password: "12345678", first_name: "Tienda", last_name: "Agricultor", internal: true)
storeuser3.add_role('store')

storeuser4 = User.create!(email: 'transporte@sercamsrl.com', phone: "900000007", location_id: location_4.id, login: "transporte@sercamsrl.com", require_password_change: false, password: "12345678", first_name: "Tienda", last_name: "Transporte", internal: true)
storeuser4.add_role('store')

supervisor_1 = User.create!(email: 'supervisor@sercamsrl.com', phone: "986976314", login: "supervisor@sercamsrl.com", require_password_change: false, password: "12345678", first_name: "Supervisor", last_name: "Sercam")
supervisor_1.add_role('supervisor')

PaymentMethod.find_or_create_by!(name: 'card', description: 'Tarj Crédito / Débito')
PaymentMethod.find_or_create_by!(name: 'cash', description: 'Efectivo')
PaymentMethod.find_or_create_by!(name: 'wallet', description: 'Yape / Plin', payment_method_type: "bank")
PaymentMethod.find_or_create_by!(name: 'banco_bcp', description: 'Banco BCP', payment_method_type: "bank")
PaymentMethod.find_or_create_by!(name: 'banco_interbank', description: 'Banco Interbank', payment_method_type: "bank")
PaymentMethod.find_or_create_by!(name: 'banco_de_la_nacion', description: 'Banco de la Nación', payment_method_type: "bank")
PaymentMethod.find_or_create_by!(name: 'banco_bbva', description: 'Banco BBVA', payment_method_type: "bank")
PaymentMethod.find_or_create_by!(name: 'banco_los_andes', description: 'Cooperativa Los Andes', payment_method_type: "bank")
PaymentMethod.find_or_create_by!(name: 'credit', description: 'Crédito', payment_method_type: "credit")

setting_ecommerce_active = Setting.find_by(name: 'ecommerce_active')
if setting_ecommerce_active&.boolean_value == true
  ecommerce_module_user_already_exists = User.find_by(email: 'ecommerce@sercamsrl.com')
  User.create!(email: 'ecommerce@sercamsrl.com', phone: "900000000", login: "ecommerce@sercamsrl.com", require_password_change: false, password: SecureRandom.alphanumeric(8), first_name: "Ecommerce", last_name: "Module", internal: true) unless ecommerce_module_user_already_exists
end

useradmin1 = User.create!(email: 'grivera@sercamsrl.com', phone: "986976366", login: "grivera@sercamsrl.com", require_password_change: false, password: "12345678", first_name: "Gerardo", last_name: "Rivera")
useradmin1.add_role('super_admin')

useradmin2 = User.create!(email: 'fserna@sercamsrl.com', phone: "986976367", login: "fserna@sercamsrl.com", require_password_change: false, password: "12345678", first_name: "Fidel", last_name: "Serna")
useradmin2.add_role('super_admin')

user1 = User.create!(email: 'augusto@devtechperu.com', phone: "986976377", login: "augusto@devtechperu.com", require_password_change: false, password: "12345678", first_name: "Augusto", last_name: "Admin")
user1.add_role('super_admin')

generic_customer = User.create!(email: 'generic_customer@devtechperu.com', phone: "986970001", login: "generic_customer@devtechperu.com", require_password_change: false, password: "12345678", first_name: "Cliente", last_name: "Genérico", internal: false)

generic_customer.add_role('customer')

generic_customer_customer = Customer.create!(
  doc_id: "99999999",
  user: generic_customer,
)

user2 = User.create!(email: 'customer1@devtechperu.com', phone: "986976378", login: "customer1@devtechperu.com", require_password_change: false, password: "12345678", first_name: "Augusto", last_name: "Samamé")
user2.add_role('customer')

Customer.create!(
  doc_id: "09344556",
  user: user2,
)

invoicer1 = Invoicer.find_or_create_by!(name: 'Sercam', razon_social: 'Sercam SRL', ruc: '20527409242', tipo_ruc: 'RUC', default: true, einvoice_api_key: "12345678901234567501", region: region_default)

invseries1 = InvoiceSeries.find_or_create_by!(invoicer: invoicer1, comprobante_type: 'factura', prefix: 'F002', next_number: 15975)
invseries2 = InvoiceSeries.find_or_create_by!(invoicer: invoicer1, comprobante_type: 'boleta', prefix: 'B002', next_number: 9368)

invseries3 = InvoiceSeries.find_or_create_by!(invoicer: invoicer1, comprobante_type: 'factura', prefix: 'F010', next_number: 2391)
invseries4 = InvoiceSeries.find_or_create_by!(invoicer: invoicer1, comprobante_type: 'boleta', prefix: 'B010', next_number: 2760)

invseries5 = InvoiceSeries.find_or_create_by!(invoicer: invoicer1, comprobante_type: 'factura', prefix: 'F003', next_number: 1141)
invseries6 = InvoiceSeries.find_or_create_by!(invoicer: invoicer1, comprobante_type: 'boleta', prefix: 'B003', next_number: 32207)

invseries7 = InvoiceSeries.find_or_create_by!(invoicer: invoicer1, comprobante_type: 'factura', prefix: 'F007', next_number: 769)
invseries8 = InvoiceSeries.find_or_create_by!(invoicer: invoicer1, comprobante_type: 'boleta', prefix: 'F008', next_number: 748)


InvoiceSeriesMapping.find_or_create_by!(location: location_1, invoice_series: invseries1, payment_method: PaymentMethod.find_by(name: 'cash'), default: true)
InvoiceSeriesMapping.find_or_create_by!(location: location_1, invoice_series: invseries2, payment_method: PaymentMethod.find_by(name: 'cash'), default: true)
InvoiceSeriesMapping.find_or_create_by!(location: location_2, invoice_series: invseries3, payment_method: PaymentMethod.find_by(name: 'cash'), default: true)
InvoiceSeriesMapping.find_or_create_by!(location: location_2, invoice_series: invseries4, payment_method: PaymentMethod.find_by(name: 'cash'), default: true)
InvoiceSeriesMapping.find_or_create_by!(location: location_3, invoice_series: invseries5, payment_method: PaymentMethod.find_by(name: 'cash'), default: true)
InvoiceSeriesMapping.find_or_create_by!(location: location_3, invoice_series: invseries6, payment_method: PaymentMethod.find_by(name: 'cash'), default: true)
InvoiceSeriesMapping.find_or_create_by!(location: location_4, invoice_series: invseries7, payment_method: PaymentMethod.find_by(name: 'cash'), default: true)
InvoiceSeriesMapping.find_or_create_by!(location: location_4, invoice_series: invseries8, payment_method: PaymentMethod.find_by(name: 'cash'), default: true)


NotificationSetting.find_or_create_by!(trigger_type: 'order', media: { notification_feed: true, dashboard_alert: true, email: true })
NotificationSetting.find_or_create_by!(trigger_type: 'preorder', media: { notification_feed: true, dashboard_alert: true, email: true })
NotificationSetting.find_or_create_by!(trigger_type: 'stock_transfer', media: { notification_feed: true, dashboard_alert: false, email: false })
NotificationSetting.find_or_create_by!(trigger_type: 'stock_transfer_partial_receipt', media: { notification_feed: true, dashboard_alert: true, email: true })
NotificationSetting.find_or_create_by!(trigger_type: 'missing_stock_periodic_inventory', media: { notification_feed: true, dashboard_alert: true, email: true })
NotificationSetting.find_or_create_by!(trigger_type: 'requisition', media: { notification_feed: true, dashboard_alert: true, email: true })

Tag.find_or_create_by!(name: 'Cementos', tag_type: 'category')
Tag.find_or_create_by!(name: 'Fierros', tag_type: 'category')
Tag.find_or_create_by!(name: 'Clavos', tag_type: 'category')
Tag.find_or_create_by!(name: 'Materiales de Construcción', tag_type: 'category')
Tag.find_or_create_by!(name: 'Materiales Eléctricos', tag_type: 'category')

Tag.find_or_create_by!(name: 'Repuestos', tag_type: 'other')

# product_1 = Product.find_or_create_by!(name: 'Cemento APU', description: "Cemento APU", price_cents: 2200, discounted_price_cents: 2200, brand: Brand.first)
# product_1.add_tag(Tag.find_by(name: 'Cementos'))
# product_2 = Product.find_or_create_by!(name: 'Cemento Sol', description: "Cemento Sol", price_cents: 2400, discounted_price_cents: 2400, brand: Brand.first)
# product_2.add_tag(Tag.find_by(name: 'Cementos'))

Services::Products::SercamProductImportService.new("sercam_product_inventory.csv").import_products_and_stocks
