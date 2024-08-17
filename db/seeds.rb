# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
setting_1 = Setting.find_or_create_by!(name: 'login_type', data_type: "type_string", internal: false, localized_name: "Tipo de Login", string_value: 'email')
setting_2 = Setting.find_or_create_by!(name: 'track_inventory', data_type: "type_boolean", internal: false, localized_name: "Medición de Inventarios", boolean_value: true)
setting_3 = Setting.find_or_create_by!(name: 'multi_region', data_type: "type_boolean", internal: false, localized_name: "Gestión de Múltiples Regiones", boolean_value: false)

brand_1 = Brand.find_or_create_by!(name: 'Infanti')
category_1 = ProductCategory.find_or_create_by!(name: 'Osos de Peluche')
category_2 = ProductCategory.find_or_create_by!(name: 'Osos de Peluche Gigantes', parent: category_1)

vendor_1 = Purchases::Vendor.find_or_create_by!(name: 'Infanti')
vendor_2 = Purchases::Vendor.find_or_create_by!(name: 'Fisher Price')
factory_1 = Factory::Factory.find_or_create_by!(name: 'Main Factory')

supplier_1 = Supplier.create!(name: "Infanti Vendor", sourceable: vendor_1)
supplier_2 = Supplier.create!(name: "Main Factory", sourceable: factory_1)

product_1 = Product.find_or_create_by!(name: 'Oso de Peluche con corazón', description: '', permalink: '', price_cents: 0, sourceable: vendor_1, brand: brand_1)

# Associate the product with categories
product_1.product_categories << category_1
product_1.product_categories << category_2

tag_1 = Tag.find_or_create_by!(name: 'Osos de Peluche')
