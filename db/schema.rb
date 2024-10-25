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

ActiveRecord::Schema[7.2].define(version: 2024_10_23_143930) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"
  enable_extension "unaccent"

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
    t.jsonb "audited_changes"
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

  create_table "cash_inflows", force: :cascade do |t|
    t.bigint "cashier_shift_id", null: false
    t.bigint "received_by_id", null: false
    t.string "custom_id", null: false
    t.text "description", null: false
    t.integer "cash_inflow_type", default: 0, null: false
    t.integer "amount_cents", null: false
    t.string "currency", default: "PEN", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cash_inflow_type"], name: "index_cash_inflows_on_cash_inflow_type"
    t.index ["cashier_shift_id"], name: "index_cash_inflows_on_cashier_shift_id"
    t.index ["custom_id"], name: "index_cash_inflows_on_custom_id", unique: true
    t.index ["received_by_id"], name: "index_cash_inflows_on_received_by_id"
  end

  create_table "cash_outflows", force: :cascade do |t|
    t.bigint "cashier_shift_id", null: false
    t.bigint "paid_to_id", null: false
    t.string "custom_id", null: false
    t.text "description", null: false
    t.integer "cash_outflow_type", default: 0, null: false
    t.integer "amount_cents", null: false
    t.string "currency", default: "PEN", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cash_outflow_type"], name: "index_cash_outflows_on_cash_outflow_type"
    t.index ["cashier_shift_id"], name: "index_cash_outflows_on_cashier_shift_id"
    t.index ["custom_id"], name: "index_cash_outflows_on_custom_id", unique: true
    t.index ["paid_to_id"], name: "index_cash_outflows_on_paid_to_id"
  end

  create_table "cashier_shifts", force: :cascade do |t|
    t.bigint "cashier_id", null: false
    t.date "date", null: false
    t.integer "total_sales_cents"
    t.datetime "opened_at", null: false
    t.datetime "closed_at"
    t.bigint "opened_by_id", null: false
    t.bigint "closed_by_id"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cashier_id"], name: "index_cashier_shifts_on_cashier_id"
    t.index ["closed_by_id"], name: "index_cashier_shifts_on_closed_by_id"
    t.index ["opened_by_id"], name: "index_cashier_shifts_on_opened_by_id"
  end

  create_table "cashier_transactions", force: :cascade do |t|
    t.bigint "cashier_shift_id", null: false
    t.string "transactable_type", null: false
    t.bigint "transactable_id", null: false
    t.bigint "payment_method_id"
    t.integer "amount_cents", null: false
    t.string "currency", default: "PEN", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cashier_shift_id"], name: "index_cashier_transactions_on_cashier_shift_id"
    t.index ["payment_method_id"], name: "index_cashier_transactions_on_payment_method_id"
    t.index ["transactable_type", "transactable_id"], name: "index_cashier_transactions_on_transactable"
  end

  create_table "cashiers", force: :cascade do |t|
    t.bigint "location_id", null: false
    t.string "name", default: "Caja Principal", null: false
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_cashiers_on_location_id"
  end

  create_table "combo_products", force: :cascade do |t|
    t.string "name", null: false
    t.integer "product_1_id", null: false
    t.integer "product_2_id", null: false
    t.integer "qty_1", null: false
    t.integer "qty_2", null: false
    t.integer "normal_price_cents", null: false
    t.integer "price_cents", null: false
    t.string "currency", default: "PEN", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "commission_payouts", force: :cascade do |t|
    t.bigint "commission_id", null: false
    t.bigint "user_id", null: false
    t.integer "amount_cents", null: false
    t.string "amount_currency", default: "PEN"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commission_id"], name: "index_commission_payouts_on_commission_id"
    t.index ["user_id"], name: "index_commission_payouts_on_user_id"
  end

  create_table "commission_ranges", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "year_month_period"
    t.decimal "min_sales", precision: 10, scale: 2, null: false
    t.decimal "max_sales", precision: 10, scale: 2
    t.decimal "commission_percentage", precision: 5, scale: 2, null: false
    t.bigint "location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id", "year_month_period"], name: "index_commission_ranges_on_location_id_and_year_month_period"
    t.index ["location_id"], name: "index_commission_ranges_on_location_id"
    t.index ["max_sales"], name: "index_commission_ranges_on_max_sales"
    t.index ["min_sales"], name: "index_commission_ranges_on_min_sales"
    t.index ["user_id"], name: "index_commission_ranges_on_user_id"
  end

  create_table "commissions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "order_id", null: false
    t.integer "sale_amount_cents", null: false
    t.integer "amount_cents", null: false
    t.string "currency", default: "PEN"
    t.integer "percentage", null: false
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_commissions_on_order_id"
    t.index ["user_id"], name: "index_commissions_on_user_id"
  end

  create_table "custom_numberings", force: :cascade do |t|
    t.integer "record_type", default: 0, null: false
    t.string "prefix", default: "", null: false
    t.integer "next_number", default: 1, null: false
    t.integer "length", default: 5, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "prefix"], name: "index_custom_numberings_on_record_type_and_prefix", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "doc_type", default: 1
    t.string "doc_id"
    t.datetime "birthdate"
    t.jsonb "avatar_data"
    t.integer "last_cart_id"
    t.integer "pricelist_id"
    t.integer "points_balance", default: 0
    t.string "referral_code"
    t.bigint "referrer_id"
    t.boolean "wants_factura", default: false
    t.string "factura_ruc"
    t.string "factura_razon_social"
    t.string "factura_direccion"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["referrer_id"], name: "index_customers_on_referrer_id"
    t.index ["user_id"], name: "index_customers_on_user_id"
  end

  create_table "discount_filters", force: :cascade do |t|
    t.bigint "discount_id", null: false
    t.string "filterable_type", null: false
    t.bigint "filterable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discount_id"], name: "index_discount_filters_on_discount_id"
    t.index ["filterable_type", "filterable_id"], name: "index_discount_filters_on_filterable"
  end

  create_table "discounts", force: :cascade do |t|
    t.string "name", null: false
    t.integer "discount_type", default: 0
    t.decimal "discount_percentage", precision: 5, scale: 2
    t.decimal "discount_fixed_amount", precision: 5, scale: 2
    t.integer "group_discount_payed_quantity"
    t.integer "group_discount_free_quantity"
    t.datetime "start_datetime"
    t.datetime "end_datetime"
    t.integer "status", default: 0
    t.integer "matching_product_ids", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discount_type"], name: "index_discounts_on_discount_type"
    t.index ["end_datetime"], name: "index_discounts_on_end_datetime"
    t.index ["matching_product_ids"], name: "index_discounts_on_matching_product_ids", using: :gin
    t.index ["start_datetime"], name: "index_discounts_on_start_datetime"
    t.index ["status"], name: "index_discounts_on_status"
  end

  create_table "factory_factories", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "region_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["region_id"], name: "index_factory_factories_on_region_id"
  end

  create_table "in_transit_stocks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "stock_transfer_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", null: false
    t.bigint "origin_warehouse_id", null: false
    t.bigint "destination_warehouse_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_warehouse_id"], name: "index_in_transit_stocks_on_destination_warehouse_id"
    t.index ["origin_warehouse_id"], name: "index_in_transit_stocks_on_origin_warehouse_id"
    t.index ["product_id"], name: "index_in_transit_stocks_on_product_id"
    t.index ["stock_transfer_id"], name: "index_in_transit_stocks_on_stock_transfer_id"
    t.index ["user_id"], name: "index_in_transit_stocks_on_user_id"
  end

  create_table "invoice_series", force: :cascade do |t|
    t.bigint "invoicer_id", null: false
    t.integer "comprobante_type", null: false
    t.string "prefix", null: false
    t.integer "next_number", null: false
    t.integer "status", default: 0, null: false
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoicer_id"], name: "index_invoice_series_on_invoicer_id"
  end

  create_table "invoice_series_mappings", force: :cascade do |t|
    t.bigint "invoice_series_id", null: false
    t.bigint "location_id", null: false
    t.bigint "payment_method_id", null: false
    t.boolean "default", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_series_id"], name: "index_invoice_series_mappings_on_invoice_series_id"
    t.index ["location_id"], name: "index_invoice_series_mappings_on_location_id"
    t.index ["payment_method_id"], name: "index_invoice_series_mappings_on_payment_method_id"
  end

  create_table "invoicers", force: :cascade do |t|
    t.bigint "region_id", null: false
    t.string "name", null: false
    t.string "razon_social", null: false
    t.string "ruc", null: false
    t.integer "tipo_ruc", default: 0, null: false
    t.integer "einvoice_integrator", default: 0, null: false
    t.string "einvoice_url"
    t.string "einvoice_api_key"
    t.string "einvoice_api_secret"
    t.boolean "default", default: false, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_invoicers_on_name", unique: true
    t.index ["region_id"], name: "index_invoicers_on_region_id"
    t.index ["ruc"], name: "index_invoicers_on_ruc", unique: true
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "invoice_series_id", null: false
    t.bigint "payment_method_id", null: false
    t.integer "amount_cents", null: false
    t.string "currency", default: "PEN", null: false
    t.string "custom_id", null: false
    t.integer "invoice_type", default: 0, null: false
    t.integer "sunat_status", default: 0, null: false
    t.text "invoice_sunat_sent_text"
    t.text "invoice_sunat_response"
    t.text "invoice_url"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["custom_id", "invoice_type", "status"], name: "index_invoices_on_custom_id_and_invoice_type_and_status", unique: true
    t.index ["invoice_series_id"], name: "index_invoices_on_invoice_series_id"
    t.index ["order_id"], name: "index_invoices_on_order_id"
    t.index ["payment_method_id"], name: "index_invoices_on_payment_method_id"
    t.index ["sunat_status"], name: "index_invoices_on_sunat_status"
  end

  create_table "locations", force: :cascade do |t|
    t.bigint "region_id", null: false
    t.string "name"
    t.string "address"
    t.string "phone"
    t.string "email"
    t.string "latitude"
    t.string "longitude"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["region_id"], name: "index_locations_on_region_id"
  end

  create_table "loyalty_tiers", force: :cascade do |t|
    t.string "name", null: false
    t.integer "requirements_orders_count"
    t.decimal "requirements_total_amount"
    t.decimal "discount_percentage"
    t.integer "free_product_id"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "notification_settings", force: :cascade do |t|
    t.string "trigger_type", null: false
    t.jsonb "media", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["trigger_type"], name: "index_notification_settings_on_trigger_type", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.string "notifiable_type", null: false
    t.bigint "notifiable_id", null: false
    t.integer "medium", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.integer "severity", default: 0, null: false
    t.text "message_title"
    t.text "message_body", null: false
    t.text "message_image"
    t.datetime "read_at"
    t.datetime "clicked_at"
    t.datetime "opened_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.decimal "quantity", precision: 10, scale: 2
    t.integer "price_cents"
    t.integer "discounted_price_cents"
    t.string "currency", default: "PEN"
    t.boolean "is_loyalty_free", default: false
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
    t.bigint "seller_id", null: false
    t.bigint "location_id", null: false
    t.bigint "region_id", null: false
    t.string "custom_id", null: false
    t.integer "order_recipient_id"
    t.integer "total_price_cents"
    t.integer "total_original_price_cents"
    t.integer "total_discount_cents"
    t.integer "shipping_price_cents"
    t.string "currency", default: "PEN"
    t.integer "cart_id"
    t.integer "shipping_address_id"
    t.integer "billing_address_id"
    t.boolean "coupon_applied", default: false
    t.text "customer_note"
    t.text "seller_note"
    t.boolean "wants_factura", default: false
    t.integer "active_invoice_id"
    t.boolean "invoice_id_required", default: false
    t.datetime "order_date"
    t.integer "origin", default: 0
    t.integer "stage", default: 1
    t.integer "payment_status", default: 0
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_invoice_id"], name: "index_orders_on_active_invoice_id", unique: true
    t.index ["cart_id"], name: "index_orders_on_cart_id"
    t.index ["custom_id"], name: "index_orders_on_custom_id", unique: true
    t.index ["location_id", "status", "order_date", "seller_id"], name: "idx_on_location_id_status_order_date_seller_id_3f1145d763"
    t.index ["location_id"], name: "index_orders_on_location_id"
    t.index ["region_id"], name: "index_orders_on_region_id"
    t.index ["seller_id"], name: "index_orders_on_seller_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "payment_methods", force: :cascade do |t|
    t.string "name", null: false
    t.string "description", null: false
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "payment_method_id", null: false
    t.bigint "user_id", null: false
    t.bigint "region_id", null: false
    t.string "payable_type", null: false
    t.bigint "payable_id", null: false
    t.bigint "cashier_shift_id", null: false
    t.string "custom_id", null: false
    t.integer "payment_request_id"
    t.integer "processor_transacion_id"
    t.integer "amount_cents", null: false
    t.string "currency", default: "PEN"
    t.datetime "payment_date", null: false
    t.text "comment"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cashier_shift_id"], name: "index_payments_on_cashier_shift_id"
    t.index ["custom_id"], name: "index_payments_on_custom_id", unique: true
    t.index ["payable_type", "payable_id"], name: "index_payments_on_payable"
    t.index ["payment_date"], name: "index_payments_on_payment_date"
    t.index ["payment_method_id"], name: "index_payments_on_payment_method_id"
    t.index ["payment_request_id"], name: "index_payments_on_payment_request_id"
    t.index ["region_id"], name: "index_payments_on_region_id"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "periodic_inventories", force: :cascade do |t|
    t.bigint "warehouse_id", null: false
    t.bigint "user_id", null: false
    t.datetime "snapshot_date", null: false
    t.integer "inventory_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inventory_type"], name: "index_periodic_inventories_on_inventory_type"
    t.index ["snapshot_date"], name: "index_periodic_inventories_on_snapshot_date"
    t.index ["status"], name: "index_periodic_inventories_on_status"
    t.index ["user_id"], name: "index_periodic_inventories_on_user_id"
    t.index ["warehouse_id"], name: "index_periodic_inventories_on_warehouse_id"
  end

  create_table "periodic_inventory_lines", force: :cascade do |t|
    t.bigint "periodic_inventory_id", null: false
    t.bigint "product_id", null: false
    t.integer "stock", null: false
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["periodic_inventory_id"], name: "index_periodic_inventory_lines_on_periodic_inventory_id"
    t.index ["product_id"], name: "index_periodic_inventory_lines_on_product_id"
    t.index ["status"], name: "index_periodic_inventory_lines_on_status"
  end

  create_table "preorders", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "order_id", null: false
    t.bigint "warehouse_id", null: false
    t.decimal "quantity", null: false
    t.decimal "fulfilled_quantity", default: "0.0", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_preorders_on_order_id"
    t.index ["product_id"], name: "index_preorders_on_product_id"
    t.index ["warehouse_id"], name: "index_preorders_on_warehouse_id"
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
    t.string "custom_id", null: false
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
    t.boolean "is_test_product", default: false
    t.datetime "available_at"
    t.datetime "deleted_at"
    t.integer "product_order", default: 0
    t.integer "status", default: 0
    t.decimal "weight", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["custom_id"], name: "index_products_on_custom_id", unique: true
    t.index ["is_test_product"], name: "index_products_on_is_test_product"
    t.index ["name"], name: "index_products_on_name"
    t.index ["product_order"], name: "index_products_on_product_order"
    t.index ["sourceable_type", "sourceable_id"], name: "index_products_on_sourceable"
    t.index ["status"], name: "index_products_on_status"
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
    t.string "custom_id", null: false
    t.datetime "purchase_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["custom_id"], name: "index_purchases_purchases_on_custom_id", unique: true
    t.index ["region_id"], name: "index_purchases_purchases_on_region_id"
    t.index ["vendor_id"], name: "index_purchases_purchases_on_vendor_id"
  end

  create_table "purchases_vendors", force: :cascade do |t|
    t.string "name", null: false
    t.string "custom_id", null: false
    t.bigint "region_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["custom_id"], name: "index_purchases_vendors_on_custom_id", unique: true
    t.index ["region_id"], name: "index_purchases_vendors_on_region_id"
  end

  create_table "regions", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "requisition_lines", force: :cascade do |t|
    t.bigint "requisition_id", null: false
    t.bigint "product_id", null: false
    t.integer "automatic_quantity", null: false
    t.integer "presold_quantity"
    t.integer "manual_quantity"
    t.integer "supplied_quantity"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_requisition_lines_on_product_id"
    t.index ["requisition_id"], name: "index_requisition_lines_on_requisition_id"
  end

  create_table "requisitions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "location_id", null: false
    t.bigint "warehouse_id", null: false
    t.string "custom_id", null: false
    t.string "stage", default: "req_pending"
    t.datetime "requisition_date", null: false
    t.text "comments"
    t.integer "requisition_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["custom_id"], name: "index_requisitions_on_custom_id", unique: true
    t.index ["location_id"], name: "index_requisitions_on_location_id"
    t.index ["user_id"], name: "index_requisitions_on_user_id"
    t.index ["warehouse_id"], name: "index_requisitions_on_warehouse_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "seller_biweekly_sales_targets", force: :cascade do |t|
    t.bigint "seller_id", null: false
    t.bigint "user_id", null: false
    t.string "year_month_period"
    t.integer "sales_target_cents", null: false
    t.string "currency", default: "PEN", null: false
    t.decimal "target_commission", precision: 5, scale: 2, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["seller_id", "year_month_period"], name: "index_targets_on_seller_id_and_year_month_period", unique: true
    t.index ["seller_id"], name: "index_seller_biweekly_sales_targets_on_seller_id"
    t.index ["user_id"], name: "index_seller_biweekly_sales_targets_on_user_id"
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

  create_table "stock_transfer_lines", force: :cascade do |t|
    t.bigint "stock_transfer_id", null: false
    t.bigint "product_id", null: false
    t.decimal "quantity", precision: 10, scale: 2, null: false
    t.decimal "received_quantity", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_stock_transfer_lines_on_product_id"
    t.index ["stock_transfer_id"], name: "index_stock_transfer_lines_on_stock_transfer_id"
  end

  create_table "stock_transfers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "origin_warehouse_id"
    t.bigint "destination_warehouse_id"
    t.string "custom_id", null: false
    t.string "guia"
    t.datetime "transfer_date", null: false
    t.text "comments"
    t.boolean "is_adjustment", default: false
    t.integer "adjustment_type", default: 0
    t.bigint "periodic_inventory_id"
    t.string "stage", default: "pending"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["custom_id"], name: "index_stock_transfers_on_custom_id", unique: true
    t.index ["destination_warehouse_id"], name: "index_stock_transfers_on_destination_warehouse_id"
    t.index ["origin_warehouse_id"], name: "index_stock_transfers_on_origin_warehouse_id"
    t.index ["periodic_inventory_id"], name: "index_stock_transfers_on_periodic_inventory_id"
    t.index ["stage"], name: "index_stock_transfers_on_stage"
    t.index ["status"], name: "index_stock_transfers_on_status"
    t.index ["transfer_date"], name: "index_stock_transfers_on_transfer_date"
    t.index ["user_id"], name: "index_stock_transfers_on_user_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name", null: false
    t.string "custom_id", null: false
    t.string "sourceable_type"
    t.bigint "sourceable_id"
    t.bigint "region_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["custom_id"], name: "index_suppliers_on_custom_id", unique: true
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
    t.integer "tag_type", default: 0
    t.boolean "visible_filter", default: false
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "user_attendance_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "location_id", null: false
    t.datetime "checkin"
    t.datetime "checkout"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_user_attendance_logs_on_location_id"
    t.index ["user_id"], name: "index_user_attendance_logs_on_user_id"
  end

  create_table "user_free_products", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "product_id", null: false
    t.bigint "loyalty_tier_id", null: false
    t.datetime "claimed_at"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loyalty_tier_id"], name: "index_user_free_products_on_loyalty_tier_id"
    t.index ["product_id"], name: "index_user_free_products_on_product_id"
    t.index ["user_id"], name: "index_user_free_products_on_user_id"
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
    t.bigint "loyalty_tier_id"
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
    t.integer "location_id"
    t.integer "warehouse_id"
    t.boolean "internal", default: false
    t.integer "status", default: 0
    t.datetime "reached_loyalty_tier_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["internal"], name: "index_users_on_internal"
    t.index ["location_id"], name: "index_users_on_location_id"
    t.index ["login"], name: "index_users_on_login", unique: true
    t.index ["loyalty_tier_id"], name: "index_users_on_loyalty_tier_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["status"], name: "index_users_on_status"
    t.index ["warehouse_id"], name: "index_users_on_warehouse_id"
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
    t.integer "location_id"
    t.boolean "is_main", default: false
    t.bigint "region_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["region_id"], name: "index_warehouses_on_region_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cash_inflows", "cashier_shifts"
  add_foreign_key "cash_inflows", "users", column: "received_by_id"
  add_foreign_key "cash_outflows", "cashier_shifts"
  add_foreign_key "cash_outflows", "users", column: "paid_to_id"
  add_foreign_key "cashier_shifts", "cashiers"
  add_foreign_key "cashier_shifts", "users", column: "closed_by_id"
  add_foreign_key "cashier_shifts", "users", column: "opened_by_id"
  add_foreign_key "cashier_transactions", "cashier_shifts"
  add_foreign_key "cashier_transactions", "payment_methods"
  add_foreign_key "cashiers", "locations"
  add_foreign_key "commission_payouts", "commissions"
  add_foreign_key "commission_payouts", "users"
  add_foreign_key "commission_ranges", "locations"
  add_foreign_key "commission_ranges", "users"
  add_foreign_key "commissions", "orders"
  add_foreign_key "commissions", "users"
  add_foreign_key "customers", "users"
  add_foreign_key "customers", "users", column: "referrer_id"
  add_foreign_key "discount_filters", "discounts"
  add_foreign_key "factory_factories", "regions"
  add_foreign_key "in_transit_stocks", "products"
  add_foreign_key "in_transit_stocks", "stock_transfers"
  add_foreign_key "in_transit_stocks", "users"
  add_foreign_key "in_transit_stocks", "warehouses", column: "destination_warehouse_id"
  add_foreign_key "in_transit_stocks", "warehouses", column: "origin_warehouse_id"
  add_foreign_key "invoice_series", "invoicers"
  add_foreign_key "invoice_series_mappings", "invoice_series"
  add_foreign_key "invoice_series_mappings", "locations"
  add_foreign_key "invoice_series_mappings", "payment_methods"
  add_foreign_key "invoicers", "regions"
  add_foreign_key "invoices", "invoice_series"
  add_foreign_key "invoices", "orders"
  add_foreign_key "invoices", "payment_methods"
  add_foreign_key "locations", "regions"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "order_sellers", "orders"
  add_foreign_key "order_sellers", "users"
  add_foreign_key "orders", "locations"
  add_foreign_key "orders", "regions"
  add_foreign_key "orders", "users"
  add_foreign_key "orders", "users", column: "seller_id"
  add_foreign_key "payments", "cashier_shifts"
  add_foreign_key "payments", "payment_methods"
  add_foreign_key "payments", "regions"
  add_foreign_key "payments", "users"
  add_foreign_key "periodic_inventories", "users"
  add_foreign_key "periodic_inventories", "warehouses"
  add_foreign_key "periodic_inventory_lines", "periodic_inventories"
  add_foreign_key "periodic_inventory_lines", "products"
  add_foreign_key "preorders", "orders"
  add_foreign_key "preorders", "products"
  add_foreign_key "preorders", "warehouses"
  add_foreign_key "product_categories", "product_categories", column: "parent_id"
  add_foreign_key "product_categories_products", "product_categories"
  add_foreign_key "product_categories_products", "products"
  add_foreign_key "purchases_purchase_lines", "products"
  add_foreign_key "purchases_purchase_lines", "purchases_purchases", column: "purchase_id"
  add_foreign_key "purchases_purchases", "purchases_vendors", column: "vendor_id"
  add_foreign_key "purchases_purchases", "regions"
  add_foreign_key "purchases_vendors", "regions"
  add_foreign_key "requisition_lines", "products"
  add_foreign_key "requisition_lines", "requisitions"
  add_foreign_key "requisitions", "locations"
  add_foreign_key "requisitions", "users"
  add_foreign_key "requisitions", "warehouses"
  add_foreign_key "seller_biweekly_sales_targets", "users"
  add_foreign_key "seller_biweekly_sales_targets", "users", column: "seller_id"
  add_foreign_key "stock_transfer_lines", "products"
  add_foreign_key "stock_transfer_lines", "stock_transfers"
  add_foreign_key "stock_transfers", "periodic_inventories"
  add_foreign_key "stock_transfers", "users"
  add_foreign_key "stock_transfers", "warehouses", column: "destination_warehouse_id"
  add_foreign_key "stock_transfers", "warehouses", column: "origin_warehouse_id"
  add_foreign_key "suppliers", "regions"
  add_foreign_key "taggings", "products"
  add_foreign_key "taggings", "tags"
  add_foreign_key "user_attendance_logs", "locations"
  add_foreign_key "user_attendance_logs", "users"
  add_foreign_key "user_free_products", "loyalty_tiers"
  add_foreign_key "user_free_products", "products"
  add_foreign_key "user_free_products", "users"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "users", "loyalty_tiers"
  add_foreign_key "warehouse_inventories", "products"
  add_foreign_key "warehouse_inventories", "warehouses"
  add_foreign_key "warehouses", "regions"
end
