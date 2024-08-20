# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2024_08_19_145703) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audits", force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "brands", force: :cascade do |t|
    t.string "name", null: false
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "factory_factories", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "region_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["region_id"], name: "index_factory_factories_on_region_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "name"
    t.bigint "region_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["region_id"], name: "index_locations_on_region_id"
  end

  create_table "media", force: :cascade do |t|
    t.jsonb "file_data", null: false
    t.integer "media_type", default: 0
    t.string "mediable_type", null: false
    t.bigint "mediable_id", null: false
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mediable_type", "mediable_id"], name: "index_media_on_mediable"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.decimal "quantity", precision: 10, scale: 2
    t.integer "price_cents"
    t.integer "discounted_price_cents"
    t.string "currency", default: "PEN"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "order_sellers", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "user_id", null: false
    t.integer "percentage", null: false
    t.integer "amount_cents", null: false
    t.string "currency", default: "PEN"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_sellers_on_order_id"
    t.index ["user_id"], name: "index_order_sellers_on_user_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "location_id", null: false
    t.bigint "region_id", null: false
    t.integer "order_recipient_id"
    t.integer "total_price_cents"
    t.integer "total_discount_cents"
    t.integer "shipping_price_cents"
    t.string "currency", default: "PEN"
    t.integer "cart_id"
    t.integer "shipping_address_id"
    t.integer "billing_address_id"
    t.boolean "coupon_applied", default: false
    t.integer "stage", default: 0
    t.integer "payment_status", default: 0
    t.integer "status", default: 0
    t.text "customer_note"
    t.text "seller_note"
    t.integer "active_invoice_id"
    t.boolean "invoice_id_required", default: false
    t.datetime "order_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_invoice_id"], name: "index_orders_on_active_invoice_id", unique: true
    t.index ["cart_id"], name: "index_orders_on_cart_id"
    t.index ["location_id"], name: "index_orders_on_location_id"
    t.index ["order_date"], name: "index_orders_on_order_date"
    t.index ["region_id"], name: "index_orders_on_region_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "payment_methods", force: :cascade do |t|
    t.string "name", null: false
    t.string "description", null: false
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "product_categories", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "parent_id"
    t.text "image"
    t.integer "product_category_type", default: 0
    t.integer "category_order", default: 0
    t.boolean "pos_visible", default: false
    t.text "pos_image"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_product_categories_on_parent_id"
  end

  create_table "product_categories_products", force: :cascade do |t|
    t.bigint "product_category_id", null: false
    t.bigint "product_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_category_id", "product_id"], name: "idx_on_product_category_id_product_id_468b5d9f0b", unique: true
    t.index ["product_category_id"], name: "index_product_categories_products_on_product_category_id"
    t.index ["product_id"], name: "index_product_categories_products_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "sku", null: false
    t.string "name", null: false
    t.integer "brand_id"
    t.text "description", null: false
    t.string "sourceable_type"
    t.bigint "sourceable_id"
    t.string "permalink", null: false
    t.integer "price_cents", null: false
    t.integer "discounted_price_cents"
    t.text "meta_keywords"
    t.text "meta_description"
    t.boolean "stockable", default: true
    t.datetime "available_at"
    t.datetime "deleted_at"
    t.integer "product_order", default: 0
    t.integer "status", default: 0
    t.decimal "weight", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sourceable_type", "sourceable_id"], name: "index_products_on_sourceable"
  end

  create_table "purchases_purchase_lines", force: :cascade do |t|
    t.bigint "purchase_id"
    t.bigint "product_id"
    t.integer "quantity", null: false
    t.decimal "price", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_purchases_purchase_lines_on_product_id"
    t.index ["purchase_id"], name: "index_purchases_purchase_lines_on_purchase_id"
  end

  create_table "purchases_purchases", force: :cascade do |t|
    t.bigint "vendor_id", null: false
    t.bigint "region_id", null: false
    t.datetime "purchase_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["region_id"], name: "index_purchases_purchases_on_region_id"
    t.index ["vendor_id"], name: "index_purchases_purchases_on_vendor_id"
  end

  create_table "purchases_vendors", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "region_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["region_id"], name: "index_purchases_vendors_on_region_id"
  end

  create_table "regions", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "settings", force: :cascade do |t|
    t.string "name", null: false
    t.string "localized_name", null: false
    t.integer "data_type", default: 0
    t.boolean "internal", default: true
    t.string "string_value"
    t.integer "integer_value"
    t.float "float_value"
    t.datetime "datetime_value"
    t.boolean "boolean_value"
    t.jsonb "hash_value"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_settings_on_name", unique: true
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name", null: false
    t.string "sourceable_type"
    t.bigint "sourceable_id"
    t.bigint "region_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["region_id"], name: "index_suppliers_on_region_id"
    t.index ["sourceable_type", "sourceable_id"], name: "index_suppliers_on_sourceable"
  end

  create_table "taggings", force: :cascade do |t|
    t.bigint "tag_id", null: false
    t.bigint "product_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_taggings_on_product_id"
    t.index ["tag_id", "product_id"], name: "index_taggings_on_tag_id_and_product_id", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "user_roles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "phone"
    t.string "login", null: false
    t.string "temporary_password"
    t.boolean "require_password_change", default: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.boolean "admin", default: false
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["login"], name: "index_users_on_login", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "warehouse_inventories", force: :cascade do |t|
    t.bigint "warehouse_id", null: false
    t.bigint "product_id", null: false
    t.integer "stock", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_warehouse_inventories_on_product_id"
    t.index ["warehouse_id", "product_id"], name: "index_warehouse_inventories_on_warehouse_id_and_product_id", unique: true
    t.index ["warehouse_id"], name: "index_warehouse_inventories_on_warehouse_id"
  end

  create_table "warehouses", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "region_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["region_id"], name: "index_warehouses_on_region_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "factory_factories", "regions"
  add_foreign_key "locations", "regions"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "order_sellers", "orders"
  add_foreign_key "order_sellers", "users"
  add_foreign_key "orders", "locations"
  add_foreign_key "orders", "regions"
  add_foreign_key "orders", "users"
  add_foreign_key "product_categories", "product_categories", column: "parent_id"
  add_foreign_key "product_categories_products", "product_categories"
  add_foreign_key "product_categories_products", "products"
  add_foreign_key "purchases_purchase_lines", "products"
  add_foreign_key "purchases_purchase_lines", "purchases_purchases", column: "purchase_id"
  add_foreign_key "purchases_purchases", "purchases_vendors", column: "vendor_id"
  add_foreign_key "purchases_purchases", "regions"
  add_foreign_key "purchases_vendors", "regions"
  add_foreign_key "suppliers", "regions"
  add_foreign_key "taggings", "products"
  add_foreign_key "taggings", "tags"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "warehouse_inventories", "products"
  add_foreign_key "warehouse_inventories", "warehouses"
  add_foreign_key "warehouses", "regions"
end
