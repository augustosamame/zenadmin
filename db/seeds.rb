# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
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

CustomNumbering.find_or_create_by!(record_type: :purchases_vendor, prefix: 'VEN', length: 5, next_number: 1, status: :active)
CustomNumbering.find_or_create_by!(record_type: :supplier, prefix: 'SUP', length: 5, next_number: 1, status: :active)
CustomNumbering.find_or_create_by!(record_type: :purchase, prefix: 'PUR', length: 5, next_number: 1, status: :active)
CustomNumbering.find_or_create_by!(record_type: :product, prefix: 'PRO', length: 5, next_number: 1, status: :active)
CustomNumbering.find_or_create_by!(record_type: :order, prefix: 'ORD', length: 5, next_number: 1, status: :active)
CustomNumbering.find_or_create_by!(record_type: :cash_inflow, prefix: 'CIN', length: 5, next_number: 1, status: :active)
CustomNumbering.find_or_create_by!(record_type: :cash_outflow, prefix: 'COU', length: 5, next_number: 1, status: :active)
CustomNumbering.find_or_create_by!(record_type: :payment, prefix: 'PAY', length: 5, next_number: 1, status: :active)
CustomNumbering.find_or_create_by!(record_type: :stock_transfer, prefix: 'INT', length: 5, next_number: 1, status: :active)

region_default = Region.find_or_create_by!(name: 'default')

brand_1 = Brand.find_or_create_by!(name: 'Jardín del Zen')
brand_2 = Brand.find_or_create_by!(name: 'Otros')
category_1 = ProductCategory.find_or_create_by!(name: 'Cremas Humectantes')
category_2 = ProductCategory.find_or_create_by!(name: 'Cremas Naturales', parent: category_1)

vendor_1 = Purchases::Vendor.find_or_create_by!(name: 'Infanti', region: region_default)
vendor_2 = Purchases::Vendor.find_or_create_by!(name: 'Fisher Price', region: region_default)
factory_1 = Factory::Factory.find_or_create_by!(name: 'Main Factory', region: region_default)

supplier_1 = Supplier.create!(name: "Infanti Vendor", sourceable: vendor_1, region: region_default)
supplier_2 = Supplier.create!(name: "Main Factory", sourceable: factory_1, region: region_default)

location_1 = Location.find_or_create_by!(name: 'Jockey Plaza', region: region_default, email: "jockeyplaza@devtechperu.com", address: 'Av. Javier Prado Este 4200, Santiago de Surco 15023', phone: '900000000')

warehouse_1 = Warehouse.find_or_create_by!(name: "Almacén Principal", region: region_default)
warehouse_2 = Warehouse.find_or_create_by!(name: "Rappi", region: region_default)
warehouse_3 = Warehouse.find_or_create_by!(name: "PedidosYa", region: region_default)
warehouse_4 = Warehouse.find_or_create_by!(name: "Almacén Jockey Plaza", location_id: location_1.id, region: region_default)

cashier_1 = Cashier.find_or_create_by!(name: "Caja Principal", location_id: location_1.id)

3.times do
  Product.transaction do
    # Create a new Product
    product = Product.new(
      custom_id: Faker::Alphanumeric.alpha(number: 10),
      name: Faker::Commerce.product_name,
      brand_id: Brand.all.sample.id, # Assuming you have some brands in your database
      description: Faker::Lorem.paragraph(sentence_count: 2),
      permalink: Faker::Internet.slug,
      discounted_price_cents: Faker::Number.between(from: 500, to: 90_000),
      meta_keywords: Faker::Lorem.words(number: 5).join(', '),
      meta_description: Faker::Lorem.sentence(word_count: 10),
      stockable: Faker::Boolean.boolean,
      available_at: Faker::Date.between(from: 2.days.ago, to: Date.today),
      deleted_at: nil, # or `Faker::Date.between(from: 1.year.ago, to: 1.day.ago)` if you want some deleted products
      product_order: Faker::Number.between(from: 1, to: 100),
      status: "active",
      weight: Faker::Number.decimal(l_digits: 2, r_digits: 2),
      price_cents: Faker::Number.between(from: 1000, to: 10000),
      sourceable: vendor_1,
      brand: brand_1
    )

    # Attach a remote image URL to the product
    media = Media.new(
      file: URI.open(Faker::LoremFlickr.image(size: "300x300", search_terms: [ 'product' ])),  # Replace with your S3 URL
      media_type: :default_image,  # Or any other media_type
      mediable: product
    )

    # Save both product and media together
    product.save!
    media.save!
  end
end


# Associate the product with categories
# product_1.product_categories << category_1
# product_1.product_categories << category_2

tag_1 = Tag.find_or_create_by!(name: 'Nuevas Fragancias')

# Product.all.each do |product|
#  WarehouseInventory.create!(product: product, warehouse: warehouse_1, stock: [ 0, 10, 20, 30, 40, 50 ].sample)
# end
# Product.all.each do |product|
#  WarehouseInventory.create!(product: product, warehouse: warehouse_2, stock: [ 0, 10, 20, 30, 40, 50 ].sample)
# end

PaymentMethod.find_or_create_by!(name: 'card', description: 'Tarjeta de Crédito / Débito')
PaymentMethod.find_or_create_by!(name: 'cash', description: 'Efectivo')
PaymentMethod.find_or_create_by!(name: 'wallet', description: 'Yape / Plin')
PaymentMethod.find_or_create_by!(name: 'pagoefectivo', description: 'Pagoefectivo')
PaymentMethod.find_or_create_by!(name: 'note', description: 'Nota de Crédito')
PaymentMethod.find_or_create_by!(name: 'points', description: 'Puntos')

if setting_6.boolean_value == true
  ecommerce_module_user_already_exists = User.find_by(email: 'ecommerce@devtechperu.com')
  User.create!(email: 'ecommerce@devtechperu.com', phone: "900000000", login: "ecommerce@devtechperu.com", require_password_change: false, password: SecureRandom.alphanumeric(8), first_name: "Ecommerce", last_name: "Module", internal: true) unless ecommerce_module_user_already_exists
end

Role.find_or_create_by!(name: 'super_admin')
Role.find_or_create_by!(name: 'admin')
Role.find_or_create_by!(name: 'seller')
Role.find_or_create_by!(name: 'customer')

user1 = User.create!(email: 'augusto@devtechperu.com', phone: "986976377", login: "augusto@devtechperu.com", require_password_change: false, password: "12345678", first_name: "Augusto", last_name: "Admin")
user1.add_role('super_admin')

CommissionRange.find_or_create_by!(user: user1, min_sales: 0, max_sales: 2000, commission_percentage: 2, location: location_1)
CommissionRange.find_or_create_by!(user: user1, min_sales: 2000, max_sales: 5000, commission_percentage: 3, location: location_1)
CommissionRange.find_or_create_by!(user: user1, min_sales: 5000, commission_percentage: 4, location: location_1)

generic_customer = User.create!(email: 'generic_customer@devtechperu.com', phone: "986970001", login: "generic_customer@devtechperu.com", require_password_change: false, password: "12345678", first_name: "Cliente", last_name: "Genérico", internal: true)
generic_customer.add_role('customer')

user2 = User.create!(email: 'customer1@devtechperu.com', phone: "986976378", login: "customer1@devtechperu.com", require_password_change: false, password: "12345678", first_name: "Augusto", last_name: "Samamé")
user2.add_role('customer')

user3 = User.create!(email: 'seller1@devtechperu.com', phone: "986976379", login: "seller1@devtechperu.com", require_password_change: false, password: "12345678", first_name: "Maria", last_name: "Angeles", location_id: location_1.id)
user3.add_role('seller')
user4 = User.create!(email: 'seller2@devtechperu.com', phone: "986976380", login: "seller2@devtechperu.com", require_password_change: false, password: "12345678", first_name: "Patricia", last_name: "Artieda", location_id: location_1.id)
user4.add_role('seller')
user5 = User.create!(email: 'seller3@devtechperu.com', phone: "986976381", login: "seller3@devtechperu.com", require_password_change: false, password: "12345678", first_name: "Mayra", last_name: "Carrillo", location_id: location_1.id)
user5.add_role('seller')

Services::Products::ProductImportService.new("productos_jardin_del_zen.csv").call_jardin_del_zen_import
