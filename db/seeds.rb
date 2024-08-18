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
setting_3 = Setting.find_or_create_by!(name: 'multi_region', data_type: "type_boolean", internal: true, localized_name: "Gestión de Múltiples Regiones", boolean_value: false)

brand_1 = Brand.find_or_create_by!(name: 'Infanti')
category_1 = ProductCategory.find_or_create_by!(name: 'Osos de Peluche')
category_2 = ProductCategory.find_or_create_by!(name: 'Osos de Peluche Gigantes', parent: category_1)

vendor_1 = Purchases::Vendor.find_or_create_by!(name: 'Infanti')
vendor_2 = Purchases::Vendor.find_or_create_by!(name: 'Fisher Price')
factory_1 = Factory::Factory.find_or_create_by!(name: 'Main Factory')

supplier_1 = Supplier.create!(name: "Infanti Vendor", sourceable: vendor_1)
supplier_2 = Supplier.create!(name: "Main Factory", sourceable: factory_1)

product_1 = Product.find_or_create_by!(sku: "OSO0001", name: 'Oso de Peluche con corazón', description: 'Oso de Peluche con corazón', permalink: 'oso-de-peluche-con-corazon', price_cents: 0, sourceable: vendor_1, brand: brand_1)
product_2 = Product.find_or_create_by!(sku: "OSO0002", name: 'Oso de Peluche rosado', description: 'Oso de Peluche rosado', permalink: 'oso-de-peluche-rosado', price_cents: 0, sourceable: vendor_1, brand: brand_1)
product_3 = Product.find_or_create_by!(sku: "OSO0003", name: 'Oso de Peluche con rosas', description: 'Oso de Peluche con rosas', permalink: 'oso-de-peluche-con-rosas', price_cents: 0, sourceable: vendor_1, brand: brand_1)

60.times do
  Product.create!(
    sku: Faker::Alphanumeric.alpha(number: 10),
    name: Faker::Commerce.product_name,
    brand_id: Brand.all.sample.id, # Assuming you have some brands in your database
    description: Faker::Lorem.paragraph(sentence_count: 2),
    image: Faker::LoremFlickr.image(size: "300x300", search_terms: ['product']),
    permalink: Faker::Internet.slug,
    price_cents: Faker::Number.between(from: 1000, to: 100_000),
    discounted_price_cents: Faker::Number.between(from: 500, to: 90_000),
    meta_keywords: Faker::Lorem.words(number: 5).join(', '),
    meta_description: Faker::Lorem.sentence(word_count: 10),
    stockable: Faker::Boolean.boolean,
    available_at: Faker::Date.between(from: 2.days.ago, to: Date.today),
    deleted_at: nil, # or `Faker::Date.between(from: 1.year.ago, to: 1.day.ago)` if you want some deleted products
    product_order: Faker::Number.between(from: 1, to: 100),
    status: Faker::Number.between(from: 0, to: 1),
    weight: Faker::Number.decimal(l_digits: 2, r_digits: 2)
  )
end


# Associate the product with categories
product_1.product_categories << category_1
product_1.product_categories << category_2

tag_1 = Tag.find_or_create_by!(name: 'Osos de Peluche')
