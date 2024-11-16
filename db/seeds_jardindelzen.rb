
setting_1 = Setting.find_or_create_by!(name: 'login_type', data_type: "type_string", internal: true, localized_name: "Tipo de Login", string_value: 'email')
setting_2 = Setting.find_or_create_by!(name: 'track_inventory', data_type: "type_boolean", internal: true, localized_name: "Medición de Inventarios", boolean_value: true)
setting_3 = Setting.find_or_create_by!(name: 'admin_2fa_required', data_type: "type_boolean", internal: false, localized_name: "Autenticación de 2 factores requerido para admin", boolean_value: false)
setting_4 = Setting.find_or_create_by!(name: 'multi_region', data_type: "type_boolean", internal: true, localized_name: "Gestión de Múltiples Regiones", boolean_value: false)
setting_5 = Setting.find_or_create_by!(name: 'max_price_discount_percentage', data_type: "type_integer", internal: false, localized_name: "Max % de descuento", integer_value: 10)
setting_6 = Setting.find_or_create_by!(name: 'ecommerce_active', data_type: "type_boolean", internal: true, localized_name: "Módulo Ecommerce Activo", boolean_value: true)
setting_7 = Setting.find_or_create_by!(name: 'pos_can_create_unpaid_orders', data_type: "type_boolean", internal: true, localized_name: "POS puede crear ventas impagas", boolean_value: false)
setting_8 = Setting.find_or_create_by!(name: 'audited_active', data_type: "type_boolean", internal: true, localized_name: "Se generan tablas de auditoría", boolean_value: true)
setting_9 = Setting.find_or_create_by!(name: 'negative_stocks_allowed', data_type: "type_boolean", internal: true, localized_name: "Se permiten stocks negativos", boolean_value: true)
setting_10 = Setting.find_or_create_by!(name: 'stock_transfers_have_in_transit_step', data_type: "type_boolean", internal: true, localized_name: "Las transferencias de stock tienen un paso intermedio En Tránsito", boolean_value: true)
setting_11 = Setting.find_or_create_by!(name: 'show_sunat_guia_for_stock_transfers', data_type: "type_boolean", internal: true, localized_name: "Mostrar guías de remisión SUNAT en transferencias de stock", boolean_value: false)
setting_12 = Setting.find_or_create_by!(name: 'multiple_invoicers_based_on_location', data_type: "type_boolean", internal: true, localized_name: "Múltiples razones sociales por tienda", boolean_value: false)
setting_13 = Setting.find_or_create_by!(name: 'multiple_invoicers_based_on_location_and_payment_method', data_type: "type_boolean", internal: true, localized_name: "Múltiples razones sociales por tienda y por medio de pago", boolean_value: true)
setting_14 = Setting.find_or_create_by!(name: 'max_total_sale_without_customer', data_type: "type_integer", internal: false, localized_name: "Maximo total de venta sin cliente", integer_value: 700)
setting_15 = Setting.find_or_create_by!(name: 'feature_flag_loyalty_program', data_type: 'type_boolean', internal: false, localized_name: 'Programa de fidelidad', boolean_value: false)
setting_16 = Setting.find_or_create_by!(name: 'multiple_cashiers_per_location', data_type: 'type_boolean', internal: false, localized_name: 'Múltiples cajeros por ubicación', boolean_value: false)
setting_17 = Setting.find_or_create_by!(name: 'feature_flag_purchases', data_type: 'type_boolean', internal: false, localized_name: 'Módulo de compras activo', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: false, hash_value: nil, status: 'active')
setting_18 = Setting.find_or_create_by!(name: 'logo_path', data_type: 'type_string', internal: false, localized_name: 'Ruta del logo', string_value: "logo_jardin_del_zen.png", integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: nil, hash_value: nil, status: 'active')
setting_19 = Setting.find_or_create_by!(name: 'feature_flag_discounts', data_type: 'type_boolean', internal: false, localized_name: 'Módulo de descuentos activo', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: true, hash_value: nil, status: 'active')
setting_20 = Setting.find_or_create_by!(name: 'feature_flag_product_packs', data_type: 'type_boolean', internal: false, localized_name: 'Módulo de paquetes de productos activo', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: true, hash_value: nil, status: 'active')
setting_21 = Setting.find_or_create_by!(name: 'feature_flag_seller_checkin', data_type: 'type_boolean', internal: false, localized_name: 'Registro de asistencia de vendedores', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: true, hash_value: nil, status: 'active')
setting_22 = Setting.find_or_create_by!(name: 'feature_flag_commission_ranges', data_type: 'type_boolean', internal: false, localized_name: 'Comisiones por rango de ventas', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: true, hash_value: nil, status: 'active')
setting_23 = Setting.find_or_create_by!(name: 'feature_flag_sales_attributed_to_seller', data_type: 'type_boolean', internal: false, localized_name: 'Ventas comisionables por vendedor', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: true, hash_value: nil, status: 'active')
setting_24 = Setting.find_or_create_by!(name: 'pos_can_create_orders_without_stock_transfers', data_type: 'type_boolean', internal: false, localized_name: 'Ventas por ubicación', string_value: nil, integer_value: nil, float_value: nil, datetime_value: nil, boolean_value: false, hash_value: nil, status: 'active')

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

brand_1 = Brand.find_or_create_by!(name: 'Jardín del Zen')
brand_2 = Brand.find_or_create_by!(name: 'Otros')


vendor_1 = Purchases::Vendor.find_or_create_by!(name: 'Infanti', region: region_default)
vendor_2 = Purchases::Vendor.find_or_create_by!(name: 'Fisher Price', region: region_default)
factory_1 = Factory::Factory.find_or_create_by!(name: 'Main Factory', region: region_default)

supplier_1 = Supplier.create!(name: "Infanti Vendor", sourceable: vendor_1, region: region_default)
supplier_2 = Supplier.create!(name: "Main Factory", sourceable: factory_1, region: region_default)

warehouse_user_1 = User.create!(email: 'almacen_principal@jardindelzen.com', phone: "986976311", login: "almacen_principal@jardindelzen.com", require_password_change: false, password: "12345678", first_name: "Almacén", last_name: "Principal", internal: true)
warehouse_user_1.add_role('warehouse_manager')

location_0 = Location.find_or_create_by!(name: 'Oficina Principal', region: region_default, email: "oficina@jardindelzen.com", address: 'Jr. Combate de Angamos 172, Santiago de Surco 15023', phone: '900000000')

warehouse_0 = Warehouse.find_by!(name: "Almacén Oficina Principal").update(is_main: true)

location_1 = Location.find_or_create_by!(name: 'Jockey Plaza', region: region_default, email: "jockeyplaza@devtechperu.com", address: 'Av. Javier Prado Este 4200, Santiago de Surco 15023', phone: '900000000')

location_2 = Location.find_or_create_by!(name: 'Plaza San Miguel', region: region_default, email: "sanmiguel@devtechperu.com", address: 'Av. La Marina 424, San Migual', phone: '900000009')

location_3 = Location.find_or_create_by!(name: 'Plaza Norte', region: region_default, email: "plazanorte@jardindelzen.com", address: 'CC Plaza Norte, Los Olivos', phone: '900000008')

location_4 = Location.find_or_create_by!(name: 'Larcomar', region: region_default, email: "larcomar@jardindelzen.com", address: 'Av. La Marina 424, San Migual', phone: '900000010')

storeuser1 = User.create!(email: 'jockeyplaza@aromaterapia.com.pe', phone: "986976311", location_id: location_1.id, login: "jockeyplaza@aromaterapia.com.pe", require_password_change: false, password: "12345678", first_name: "Tienda", last_name: "Jockey Plaza", internal: true)
storeuser1.add_role('store')

storeuser2 = User.create!(email: 'sanmiguel@aromaterapia.com.pe', phone: "986976312", location_id: location_2.id, login: "sanmiguel@aromaterapia.com.pe", require_password_change: false, password: "12345678", first_name: "Tienda", last_name: "Plaza San Miguel", internal: true)
storeuser2.add_role('store')

storeuser3 = User.create!(email: 'plazanorte@aromaterapia.com.pe', phone: "928855854", location_id: location_3.id, login: "plazanorte@aromaterapia.com.pe", require_password_change: false, password: "12345678", first_name: "Tienda", last_name: "Plaza Norte", internal: true)
storeuser3.add_role('store')

storeuser4 = User.create!(email: 'larcomar@aromaterapia.com.pe', phone: "928855855", location_id: location_4.id, login: "larcomar@aromaterapia.com.pe", require_password_change: false, password: "12345678", first_name: "Tienda", last_name: "Larcomar", internal: true)
storeuser4.add_role('store')

supervisor_1 = User.create!(email: 'supervisor@aromaterapia.com.pe', phone: "986976314", login: "supervisor@aromaterapia.com.pe", require_password_change: false, password: "12345678", first_name: "Carmen", last_name: "Supervisor")
supervisor_1.add_role('supervisor')

warehouse_2 = Warehouse.find_or_create_by!(name: "Rappi", region: region_default)
warehouse_3 = Warehouse.find_or_create_by!(name: "PedidosYa", region: region_default)


PaymentMethod.find_or_create_by!(name: 'card', description: 'Tarj Crédito / Débito')
PaymentMethod.find_or_create_by!(name: 'cash', description: 'Efectivo')
PaymentMethod.find_or_create_by!(name: 'wallet', description: 'Yape / Plin')
PaymentMethod.find_or_create_by!(name: 'pagoefectivo', description: 'Pagoefectivo')
PaymentMethod.find_or_create_by!(name: 'note', description: 'Nota de Crédito')
PaymentMethod.find_or_create_by!(name: 'points', description: 'Puntos')
PaymentMethod.find_or_create_by!(name: 'miles', description: 'Millas')
PaymentMethod.find_or_create_by!(name: 'apps', description: 'Rappi / PedidosYa')

if setting_6.boolean_value == true
  ecommerce_module_user_already_exists = User.find_by(email: 'ecommerce@devtechperu.com')
  User.create!(email: 'ecommerce@devtechperu.com', phone: "900000000", login: "ecommerce@devtechperu.com", require_password_change: false, password: SecureRandom.alphanumeric(8), first_name: "Ecommerce", last_name: "Module", internal: true) unless ecommerce_module_user_already_exists
end

user1 = User.create!(email: 'augusto@devtechperu.com', phone: "986976377", login: "augusto@devtechperu.com", require_password_change: false, password: "12345678", first_name: "Augusto", last_name: "Admin")
user1.add_role('super_admin')

CommissionRange.find_or_create_by!(user: user1, min_sales: 0, max_sales: 2000, commission_percentage: 2, location: location_1, year_month_period: "2024_09_II")
CommissionRange.find_or_create_by!(user: user1, min_sales: 2000, max_sales: 5000, commission_percentage: 3, location: location_1, year_month_period: "2024_09_II")
CommissionRange.find_or_create_by!(user: user1, min_sales: 5000, commission_percentage: 4, location: location_1, year_month_period: "2024_09_II")
CommissionRange.find_or_create_by!(user: user1, min_sales: 0, commission_percentage: 7, location: location_4, year_month_period: "2024_11_I")
CommissionRange.find_or_create_by!(user: user1, min_sales: 7001, commission_percentage: 9, location: location_4, year_month_period: "2024_11_I")
CommissionRange.find_or_create_by!(user: user1, min_sales: 9501, commission_percentage: 13, location: location_4, year_month_period: "2024_11_I")
CommissionRange.find_or_create_by!(user: user1, min_sales: 12001, commission_percentage: 15, location: location_4, year_month_period: "2024_11_I")

useradmin1 = User.create!(email: 'aalvarino@aromaterapia.com.pe', phone: "986976366", login: "aalvarino@aromaterapia.com.pe", require_password_change: false, password: "12345678", first_name: "Alicia", last_name: "Alvarino")
useradmin1.add_role('super_admin')

useradmin2 = User.create!(email: 'administrador@aromaterapia.com.pe', phone: "986976367", login: "administrador@aromaterapia.com.pe", require_password_change: false, password: "12345678", first_name: "Sasha", last_name: "Admin")
useradmin2.add_role('super_admin')

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

[
  "Abellud Figueroa afigue@aromaterapia.com.pe 12345678 928855845",
  "Ricardo Morao rmorao@aromaterapia.com.pe 12345678 907488874",
  "Jeannelly Reyes jreyes@aromaterapia.com.pe 12345678 927461873",
  "Reishell Doncal rdoncal@aromaterapia.com.pe 12345678 902609704",
  "Orlando Suarez osuare@aromaterapia.com.pe 12345678 920992372",
  "Gianely Pedernez gpederne@aromaterapia.com.pe 12345678 926824979",
  "Mario Mujica mmujica@aromaterapia.com.pe 12345678 943279987",
  "Rosseline Lucho rlucho@aromaterapia.com.pe 12345678 933397687",
  "Nils Frick nfrick@aromaterapia.com.pe 12345678 931887453",
  "Steffany Gavilan sgavila@aromaterapia.com.pe 12345678 932843289",
  "Patricia Pisconte ppiscont@aromaterapia.com.pe 12345678 924163827",
  "Evelin Yarasca eyaras@aromaterapia.com.pe 12345678 947071687",
  "Yanira Remigio yremigi@aromaterapia.com.pe 12345678 981537710",
  "Valeria Perez vperez@aromaterapia.com.pe 12345678 965991870",
  "Mayra Morales mmorale@aromaterapia.com.pe 12345678 976793464",
  "Claudia Chuquimantari cchuqui@aromaterapia.com.pe 12345678 981524291",
  "Leidy Coregana lcoregan@aromaterapia.com.pe 12345678 957243394",
  "Diana Santillan dsantill@aromaterapia.com.pe 12345678 933153900",
  "Camila Quispe cquispe@aromaterapia.com.pe 12345678 987976413",
  "Mayke Elliott melliot@aromaterapia.com.pe 12345678 937259915",
  "Eglis Mendez emendez@aromaterapia.com.pe 12345678 979337174",
  "Yesenia Quispe yquispe@aromaterapia.com.pe 12345678 981524291",
  "Carmen Hernandez cherna@aromaterapia.com.pe 12345678 980198604",
  "Stephanie Sandoval ssandova@aromaterapia.com.pe 12345678 987969512"
].each do |user_info|
  first_name, last_name, email, password, phone = user_info.split
  user = User.create!(
    email: email,
    phone: phone,
    login: email,
    require_password_change: false,
    password: password,
    first_name: first_name,
    last_name: last_name,
    location_id: nil
  )
  user.add_role('seller')
  puts "Created user: #{user.email}"
end

invoicer1 = Invoicer.find_or_create_by!(name: 'El Jardin del Zen', razon_social: 'El Jardin del Zen EIRL', ruc: '20513903180', tipo_ruc: 'RUC', default: true, einvoice_api_key: "12345678901234561354", region: region_default)
invoicer2 = Invoicer.find_or_create_by!(name: 'Laboratorio Cuerpo y Alma', razon_social: 'Laboratorio Cuerpo y Alma EIRL', ruc: '20518549937', tipo_ruc: 'RUC', einvoice_api_key: "12345678901234561355", region: region_default)
invoicer3 = Invoicer.find_or_create_by!(name: 'Alicia Alvariño Garland', razon_social: 'Alicia Alvariño Garland', ruc: '10078741258', tipo_ruc: 'RUS', einvoice_api_key: "12345678901220560554", region: region_default)
invoicer4 = Invoicer.find_or_create_by!(name: 'Maria Isabel Garland', razon_social: 'Maria Isabel Garland', ruc: '10107907365', tipo_ruc: 'RUS', einvoice_api_key: "", region: region_default)

invseries1 = InvoiceSeries.find_or_create_by!(invoicer: invoicer2, comprobante_type: 'factura', prefix: 'F016', next_number: 1)
invseries2 = InvoiceSeries.find_or_create_by!(invoicer: invoicer2, comprobante_type: 'boleta', prefix: 'B016', next_number: 1)

invseries3 = InvoiceSeries.find_or_create_by!(invoicer: invoicer1, comprobante_type: 'factura', prefix: 'F021', next_number: 1)
invseries4 = InvoiceSeries.find_or_create_by!(invoicer: invoicer1, comprobante_type: 'boleta', prefix: 'B021', next_number: 1)

invseries5 = InvoiceSeries.find_or_create_by!(invoicer: invoicer3, comprobante_type: 'boleta', prefix: 'B003', next_number: 1)

invseries6 = InvoiceSeries.find_or_create_by!(invoicer: invoicer2, comprobante_type: 'factura', prefix: 'F019', next_number: 1)
invseries7 = InvoiceSeries.find_or_create_by!(invoicer: invoicer2, comprobante_type: 'boleta', prefix: 'B019', next_number: 1)
invseries8 = InvoiceSeries.find_or_create_by!(invoicer: invoicer2, comprobante_type: 'factura', prefix: 'F017', next_number: 1)
invseries9 = InvoiceSeries.find_or_create_by!(invoicer: invoicer3, comprobante_type: 'boleta', prefix: 'B017', next_number: 1)


InvoiceSeriesMapping.find_or_create_by!(location: location_2, invoice_series: invseries3, payment_method: PaymentMethod.find_by(name: 'card'), default: true)
InvoiceSeriesMapping.find_or_create_by!(location: location_2, invoice_series: invseries4, payment_method: PaymentMethod.find_by(name: 'card'), default: true)
InvoiceSeriesMapping.find_or_create_by!(location: location_2, invoice_series: invseries5, payment_method: PaymentMethod.find_by(name: 'cash'))

InvoiceSeriesMapping.find_or_create_by!(location: location_3, invoice_series: invseries6, payment_method: PaymentMethod.find_by(name: 'card'), default: true)
InvoiceSeriesMapping.find_or_create_by!(location: location_3, invoice_series: invseries7, payment_method: PaymentMethod.find_by(name: 'card'), default: true)

InvoiceSeriesMapping.find_or_create_by!(location: location_4, invoice_series: invseries8, payment_method: PaymentMethod.find_by(name: 'card'), default: true)
InvoiceSeriesMapping.find_or_create_by!(location: location_4, invoice_series: invseries9, payment_method: PaymentMethod.find_by(name: 'cash'), default: false)
NotificationSetting.find_or_create_by!(trigger_type: 'order', media: { notification_feed: true, dashboard_alert: true, email: true })
NotificationSetting.find_or_create_by!(trigger_type: 'preorder', media: { notification_feed: true, dashboard_alert: true, email: true })
NotificationSetting.find_or_create_by!(trigger_type: 'stock_transfer', media: { notification_feed: true, dashboard_alert: false, email: false })
NotificationSetting.find_or_create_by!(trigger_type: 'stock_transfer_partial_receipt', media: { notification_feed: true, dashboard_alert: true, email: true })
NotificationSetting.find_or_create_by!(trigger_type: 'missing_stock_periodic_inventory', media: { notification_feed: true, dashboard_alert: true, email: true })
NotificationSetting.find_or_create_by!(trigger_type: 'requisition', media: { notification_feed: true, dashboard_alert: true, email: true })

SellerBiweeklySalesTarget.find_or_create_by!(user: useradmin2, seller: supervisor_1, sales_target_cents: 100000, year_month_period: "2024_08_I", location: location_1, currency: "PEN", target_commission: 5.0)
SellerBiweeklySalesTarget.find_or_create_by!(user: useradmin2, seller: supervisor_1, sales_target_cents: 100000, year_month_period: "2024_08_II", location: location_1, currency: "PEN", target_commission: 5.0)
SellerBiweeklySalesTarget.find_or_create_by!(user: useradmin2, seller: supervisor_1, sales_target_cents: 100000, year_month_period: "2024_09_I", location: location_1, currency: "PEN", target_commission: 5.0)
SellerBiweeklySalesTarget.find_or_create_by!(user: useradmin2, seller: supervisor_1, sales_target_cents: 100000, year_month_period: "2024_09_II", location: location_1, currency: "PEN", target_commission: 5.0)

random_products = Product.order("RANDOM()").limit(4).pluck(:id)

LoyaltyTier.find_or_create_by!(name: 'Silver', requirements_orders_count: 20, requirements_total_amount: 2000, discount_percentage: 0.10, free_product_id: random_sercamsrls[0])
LoyaltyTier.find_or_create_by!(name: 'Gold', requirements_orders_count: 30, requirements_total_amount: 3000, discount_percentage: 0.15, free_product_id: random_products[1])
LoyaltyTier.find_or_create_by!(name: 'Platinum', requirements_orders_count: 40, requirements_total_amount: 4000, discount_percentage: 0.20, free_product_id: random_products[2])
LoyaltyTier.find_or_create_by!(name: 'Diamond', requirements_orders_count: 50, requirements_total_amount: 5000, discount_percentage: 0.25, free_product_id: random_products[3])

Tag.find_or_create_by!(name: 'Jabones', tag_type: 'category')
Tag.find_or_create_by!(name: 'Cremas', tag_type: 'category')
Tag.find_or_create_by!(name: 'Aceites', tag_type: 'category')
Tag.find_or_create_by!(name: 'Sales De Baño', tag_type: 'category')
Tag.find_or_create_by!(name: 'Aceites Esenciales', tag_type: 'category')
Tag.find_or_create_by!(name: 'Aromatizadores', tag_type: 'category')
Tag.find_or_create_by!(name: 'Colonias Y Perfumes', tag_type: 'category')
Tag.find_or_create_by!(name: 'Accesorios', tag_type: 'category')

Tag.find_or_create_by!(name: 'Exfoliantes', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Jabones'))
Tag.find_or_create_by!(name: 'Burbujas', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Jabones'))
Tag.find_or_create_by!(name: 'Jabones En Barra', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Jabones'))
Tag.find_or_create_by!(name: 'Jabones De Rostro', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Jabones'))
Tag.find_or_create_by!(name: 'Jabones Antique', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Jabones'))
Tag.find_or_create_by!(name: 'Jabones Herbales', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Jabones'))
Tag.find_or_create_by!(name: 'Jabones Aromandina', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Jabones'))
Tag.find_or_create_by!(name: 'Jabones De Glicerina', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Jabones'))
Tag.find_or_create_by!(name: 'Espuma Exfoliante', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Jabones'))
Tag.find_or_create_by!(name: 'Jabones Espumosos', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Jabones'))
Tag.find_or_create_by!(name: 'Antibacteriales', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Jabones'))
# Tag.find_or_create_by!(name: 'Cremas', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Cremas'))
Tag.find_or_create_by!(name: 'Lociones', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Cremas'))
Tag.find_or_create_by!(name: 'Aceites Nutritivos', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Aceites'))
Tag.find_or_create_by!(name: 'Aceites Para Masajes', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Aceites'))
Tag.find_or_create_by!(name: 'Exfoliantes Oleosos', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Aceites'))
Tag.find_or_create_by!(name: 'Fragancias', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Aromatizadores'))
Tag.find_or_create_by!(name: 'Velas', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Aromatizadores'))
Tag.find_or_create_by!(name: 'Difusores', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Aromatizadores'))
Tag.find_or_create_by!(name: 'Inciensos', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Aromatizadores'))
Tag.find_or_create_by!(name: 'Potpourri', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Aromatizadores'))
Tag.find_or_create_by!(name: 'Bamboo', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Aromatizadores'))
Tag.find_or_create_by!(name: 'Sprays', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Aromatizadores'))
Tag.find_or_create_by!(name: 'Cajoneras', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Aromatizadores'))
# Tag.find_or_create_by!(name: 'Accesorios', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Accesorios'))
Tag.find_or_create_by!(name: 'Almohadillas', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Accesorios'))
Tag.find_or_create_by!(name: 'Almohadillas Terapéuticas', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Accesorios'))
Tag.find_or_create_by!(name: 'Almohadillas Ensueño', tag_type: 'sub_category', parent_tag: Tag.find_by(name: 'Accesorios'))

Tag.find_or_create_by!(name: 'Amor', tag_type: 'fragance')
Tag.find_or_create_by!(name: 'Felicidad', tag_type: 'fragance')
Tag.find_or_create_by!(name: 'Serenidad', tag_type: 'fragance')
Tag.find_or_create_by!(name: 'Tranquilidad', tag_type: 'fragance')
Tag.find_or_create_by!(name: 'Armonía', tag_type: 'fragance')
Tag.find_or_create_by!(name: 'Energía', tag_type: 'fragance')
Tag.find_or_create_by!(name: 'Hierba Luisa', tag_type: 'fragance')
Tag.find_or_create_by!(name: '10 Ml', tag_type: 'capacity')
Tag.find_or_create_by!(name: '20 Ml', tag_type: 'capacity')
Tag.find_or_create_by!(name: '30 Ml', tag_type: 'capacity')
Tag.find_or_create_by!(name: '50 Ml', tag_type: 'capacity')
Tag.find_or_create_by!(name: '60 Ml', tag_type: 'capacity')
Tag.find_or_create_by!(name: '100 Ml', tag_type: 'capacity')
Tag.find_or_create_by!(name: '120 Ml', tag_type: 'capacity')
Tag.find_or_create_by!(name: '150 Ml', tag_type: 'capacity')
Tag.find_or_create_by!(name: '173 Ml', tag_type: 'capacity')
Tag.find_or_create_by!(name: '180 Ml', tag_type: 'capacity')
Tag.find_or_create_by!(name: '200 Ml', tag_type: 'capacity')
Tag.find_or_create_by!(name: '240 Ml', tag_type: 'capacity')
Tag.find_or_create_by!(name: '520 Ml', tag_type: 'capacity')
Tag.find_or_create_by!(name: '550 Ml', tag_type: 'capacity')
Tag.find_or_create_by!(name: '1 Lt', tag_type: 'capacity')
Tag.find_or_create_by!(name: '33 Gr', tag_type: 'weight')
Tag.find_or_create_by!(name: '60 Gr', tag_type: 'weight')
Tag.find_or_create_by!(name: '66 Gr', tag_type: 'weight')
Tag.find_or_create_by!(name: '80 Gr', tag_type: 'weight')
Tag.find_or_create_by!(name: '100 Gr', tag_type: 'weight')
Tag.find_or_create_by!(name: '180 Gr', tag_type: 'weight')
Tag.find_or_create_by!(name: '190 Gr', tag_type: 'weight')
Tag.find_or_create_by!(name: '200 Gr', tag_type: 'weight')
Tag.find_or_create_by!(name: '400 Gr', tag_type: 'weight')
Tag.find_or_create_by!(name: '520 Gr', tag_type: 'weight')
Tag.find_or_create_by!(name: 'Repuestos', tag_type: 'other')


Services::Products::ProductImportService.new("productos_y_etiquetas_jardin_del_zen.csv").call
# Services::Products::InitialStockImportService.new("stock_location_id_3.csv").call
# Services::Products::ImportProductPricesService.new("reporte_de_precios.csv").call
Services::Products::InitialStockImportService.new("jardin_del_zen_stock_and_price_report.csv").stock_and_prices
