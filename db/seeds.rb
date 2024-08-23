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

brand_1 = Brand.find_or_create_by!(name: 'Infanti')
category_1 = ProductCategory.find_or_create_by!(name: 'Osos de Peluche')
category_2 = ProductCategory.find_or_create_by!(name: 'Osos de Peluche Gigantes', parent: category_1)

vendor_1 = Purchases::Vendor.find_or_create_by!(name: 'Infanti')
vendor_2 = Purchases::Vendor.find_or_create_by!(name: 'Fisher Price')
factory_1 = Factory::Factory.find_or_create_by!(name: 'Main Factory')

supplier_1 = Supplier.create!(name: "Infanti Vendor", sourceable: vendor_1)
supplier_2 = Supplier.create!(name: "Main Factory", sourceable: factory_1)

warehouse_1 = Warehouse.find_or_create_by!(name: "Almacén Principal")

# product_1 = Product.find_or_create_by!(sku: "OSO0001", image: Faker::LoremFlickr.image(size: "300x300", search_terms: [ 'product' ]), name: 'Oso de Peluche con corazón', description: 'Oso de Peluche con corazón', permalink: 'oso-de-peluche-con-corazon', price_cents: 4000, sourceable: vendor_1, brand: brand_1)
# product_2 = Product.find_or_create_by!(sku: "OSO0002", image: Faker::LoremFlickr.image(size: "300x300", search_terms: [ 'product' ]), name: 'Oso de Peluche rosado', description: 'Oso de Peluche rosado', permalink: 'oso-de-peluche-rosado', price_cents: 8000, sourceable: vendor_1, brand: brand_1)
# product_3 = Product.find_or_create_by!(sku: "OSO0003", image: Faker::LoremFlickr.image(size: "300x300", search_terms: [ 'product' ]), name: 'Oso de Peluche con rosas', description: 'Oso de Peluche con rosas', permalink: 'oso-de-peluche-con-rosas', price_cents: 2500, sourceable: vendor_1, brand: brand_1)

20.times do
  Product.transaction do
    # Create a new Product
    product = Product.new(
      sku: Faker::Alphanumeric.alpha(number: 10),
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
      status: Faker::Number.between(from: 0, to: 1),
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

tag_1 = Tag.find_or_create_by!(name: 'Osos de Peluche')

Product.all.each do |product|
  WarehouseInventory.create!(product: product, warehouse: warehouse_1, stock: [ 0, 10, 20, 30, 40, 50 ].sample)
end

PaymentMethod.find_or_create_by!(name: 'card', description: 'Tarjeta de Crédito / Débito')
PaymentMethod.find_or_create_by!(name: 'cash', description: 'Efectivo')
PaymentMethod.find_or_create_by!(name: 'wallet', description: 'Yape / Plin')
PaymentMethod.find_or_create_by!(name: 'pagoefectivo', description: 'Pagoefectivo')
PaymentMethod.find_or_create_by!(name: 'note', description: 'Nota de Crédito')
PaymentMethod.find_or_create_by!(name: 'points', description: 'Puntos')

Location.find_or_create_by!(name: 'Jockey Plaza', region: Region.first, address: 'Av. Javier Prado Este 4200, Santiago de Surco 15023', phone: '900000000', seller_comission_percentage: 5.0)

if setting_6.boolean_value == true
  ecommerce_module_user_already_exists = User.find_by(email: 'ecommerce@devtechperu.com')
  User.create!(email: 'ecommerce@devtechperu.com', phone: "900000000", require_password_change: false, password: SecureRandom.alphanumeric(8), first_name: "Ecommerce", last_name: "Module") unless ecommerce_module_user_already_exists
end

Role.find_or_create_by!(name: 'super_admin')
Role.find_or_create_by!(name: 'admin')
Role.find_or_create_by!(name: 'seller')
Role.find_or_create_by!(name: 'customer')

user1 = User.create!(email: 'augusto@devtechperu.com', phone: "986976377", require_password_change: false, password: "12345678", first_name: "Augusto", last_name: "Admin")
user1.add_role('super_admin')

generic_customer = User.create!(email: 'generic_customer@devtechperu.com', phone: "986970001", require_password_change: false, password: "12345678", first_name: "Cliente", last_name: "Genérico")
generic_customer.add_role('customer')

user2 = User.create!(email: 'customer1@devtechperu.com', phone: "986976378", require_password_change: false, password: "12345678", first_name: "Customer", last_name: "One")
user2.add_role('customer')

user3 = User.create!(email: 'seller1@devtechperu.com', phone: "986976379", require_password_change: false, password: "12345678", first_name: "Seller", last_name: "One")
user3.add_role('seller')
user4 = User.create!(email: 'seller2@devtechperu.com', phone: "986976380", require_password_change: false, password: "12345678", first_name: "Seller", last_name: "Two")
user4.add_role('seller')
user5 = User.create!(email: 'seller3@devtechperu.com', phone: "986976381", require_password_change: false, password: "12345678", first_name: "Seller", last_name: "Three")
user5.add_role('seller')
