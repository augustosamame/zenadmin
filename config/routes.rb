require "sidekiq/web"

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"
  mount Shrine.presign_endpoint(:cache) => "/s3/params"

  if Rails.env.development? || Rails.env.test?
    mount Railsui::Engine, at: "/railsui"
  end

  get "pricing", to: "page#pricing"
  get "about", to: "page#about"

  get "invoice/:id", to: "orders#invoice", as: :invoice
  get "invoice_xml/:id", to: "orders#invoice_xml", as: :invoice_xml
  # create a namespace for admin
  namespace :admin do
    resources :products do
      collection do
        get :bulk_tag
        post :apply_bulk_tags
        get :search
        get :search_by_code
        get :search_by_name
        get :search_by_category
        get :search_by_subcategory
        get :search_by_brand
        get :search_by_tag
        get :search_by_barcode
        get :search_by_supplier
        get :search_by_price_range
        get :search_by_stock_range
        get :search_by_created_at
        get :search_by_updated_at
        get :search_by_status
        get :search_by_featured
        get :search_by_discount
        get :search_by_discount_range
        get :search_by_discount_start_date
        get :search_by_discount_end_date
        get :search_by_discount_status
        get :search_by_discount_type
        get :search_by_discount_value
        get :search_by_discount_value_range
        get :search_by_discount_percentage
        get :search_by_discount_percentage_range
        get :search_by_discount_amount
        get :search_by_discount_amount_range
        get :search_by_discount_min_quantity
        get :search_by_discount_max_quantity
        get :search_by_discount_min_amount
        get :search_by_discount_max_amount
        get :search_by_discount_min_percentage
        get :search_by_discount_max_percentage
        get :search_by_discount_min_value
        get :search_by_discount_max_value
        get :search_by_discount_min_created_at
        get :search_by_discount_max_created_at
        get :search_by_discount_min_updated_at
        get :search_by_discount_max_updated_at
        get :search_by_discount_min_start_date
        get :search_by_discount_max_start_date
        get :search_by_discount_min_end_date
        get :search_by_discount_max_end_date
        get :search_by_discount_min_status
        get :search_by_discount_max_status
        get :search_by_discount_min_type
        get :search_by_discount_max_type
        get :search_by_discount_min_value_range
        get :search_by_discount_max_value_range
        get :search_by_discount_min_percentage_range
        get :search_by_discount_max_percentage_range
        get :search_by_discount_min_amount_range
        get :search_by_discount_max_amount_range
        get :customer_prices
        get :default_prices
      end
      resources :media, module: :admin
      post "evaluate_group_discount", on: :collection
      get "search", on: :collection
      get "products_matching_tags", on: :collection
      get "customer_prices", on: :collection
      get "combo_products_show", on: :member
      member do
        get :stock
      end
    end

    resources :products_stock, only: [:index]

    post "face_recognition", to: "face_recognition#recognize"

    resources :product_categories, except: [ :show ] do
      resources :media, module: :admin
    end


    resources :requisitions do
      member do
        patch :fulfill
      end
      resources :requisition_lines
    end

    resources :orders, only: [ :index, :new, :create, :update, :show, :edit, :update ] do
      member do
        post :retry_invoice
        get :universal_invoice_show
        get :edit_commissions
        get :edit_payments
        patch :update_payments
        post :void
      end
      collection do
        get "pos"
      end

      resources :external_invoices, only: [ :new, :create, :destroy ]
    end

    resources :voided_orders, only: [ :index, :show ]

    resources :payments, only: [ :index, :show, :new, :create ]
    resources :payment_methods
    resources :price_lists
    resources :users do
      member do
        get "loyalty_info"
        patch "update_contact_info"
        get "check_roles"
        get "unpaid_orders"
      end
    end
    get "sellers", to: "users#sellers"

    resources :user_attendance_logs, only: [ :index, :new, :create, :edit, :update ] do
      collection do
        get "check_attendance_status"
        get "seller_checkout"
        get "seller_checkin_status"
        get "location_sellers"
        get "seller_attendance_report"
        get "location_attendance_report"
        post "compare_face"
      end
    end

    resources :customers
    post "pos_create_customer", to: "users#create_customer"
    get "search_dni", to: "customers#search_dni"
    get "search_ruc", to: "customers#search_ruc"

    resources :locations do
      member do
        get :commission_ranges
      end
      collection do
        get :sales_targets
      end
    end
    resources :commission_ranges
    resources :seller_biweekly_sales_targets do
      collection do
        get "seller_data"
      end
    end

    resources :warehouses
    patch "/set_current_warehouse", to: "warehouses#set_current_warehouse"
    get "inventory", to: "inventory/inventory#show"

    namespace :inventory do
      get "kardex", to: "kardex#show"
      get "fetch_kardex_movements", to: "kardex#fetch_kardex_movements"
      get "product_min_max_stocks", to: "product_min_max_stocks#index"
      post "product_min_max_stocks", to: "product_min_max_stocks#create"
      resources :periodic_inventories, only: [ :index, :new, :create, :show ] do
        collection do
          post :print_inventory_list
        end
      end
    end

    resources :stock_transfers do
      collection do
        get "index_stock_adjustments"
      end
      member do
        patch :set_to_in_transit
        get :initiate_receive
        post :execute_receive
        patch :adjustment_stock_transfer_admin_confirm
      end
    end
    resources :planned_stock_transfers do
      member do
        post :create_stock_transfer
      end
    end
    resources :in_transit_stocks
    resources :transportistas
    resources :combo_products
    resources :product_packs
    resources :discount_products
    resources :discounts do
      get "matching_products", on: :collection
    end
    resources :cashier_shifts do
      member do
        patch :close
        patch :modify_initial_balance
      end
    end

    resources :cashier_transactions, only: [ :new, :create ]
    resources :commissions, only: [ :index, :show ]
    resources :loyalty_tiers
    resources :invoicers do
      get "invoice_series", on: :member
    end
    resources :invoice_series
    resources :invoice_series_mappings

    resources :tags, only: [ :index, :new, :create, :edit, :update, :destroy ]

    resources :account_receivables, only: [ :index, :show ] do
      get "users_index", on: :collection
      get "payments_calendar", on: :collection
      post "create_initial_balance", on: :collection
    end

    resources :account_receivable_payments do
      collection do
        get :success
        get :error
      end
    end

    resources :purchase_orders do
      member do
        post :create_purchase
      end
    end

    resources :purchases

    resources :vendors
    
    resources :orders_per_product, only: [ :index ]

    get "sales_dashboard", to: "dashboards#sales_dashboard"
    get "cashiers_dashboard", to: "dashboards#cashiers_dashboard"
    get "sales_ranking", to: "dashboards#sales_ranking"
    post "dashboards/set_location", to: "dashboards#set_location"

    resources :dashboards, only: [] do
      collection do
        get :payments_calendar
      end
    end

    get "reports/form", to: "reports#reports_form"
    post "reports/generate", to: "reports#generate"
    get "reports/cash_flow", to: "reports#cash_flow"
    get "reports/inventory_out", to: "reports#inventory_out"
    get "reports/consolidated", to: "reports#consolidated"

    resources :consolidated_sales, only: [ :index ]
    get "reports/consolidated_sales", to: "consolidated_sales#index"

    resources :grouped_sales, only: [ :index ]
    get "reports/grouped_sales", to: "grouped_sales#index"

    resources :stock_transfers_with_differences, only: [ :index ] do
      member do
        put :accept_origin_quantity
        put :accept_destination_quantity
      end
    end
    get "reports/stock_transfers_with_differences", to: "stock_transfers_with_differences#index"

    get "integrations", to: "page#integrations"
    get "team", to: "page#team"
    get "billing", to: "page#billing"
    get "notifications", to: "page#notifications"
    get "settings", to: "page#settings"
    get "activity", to: "page#activity"
    get "profile", to: "page#profile"
    get "people", to: "page#people"
    get "calendar", to: "page#calendar"
    get "assignments", to: "page#assignments"
    get "message", to: "page#message"
    get "messages", to: "page#messages"
    get "project", to: "page#project"
    get "projects", to: "page#projects"

    get 'nota_de_venta/:id', to: 'nota_de_venta#show', as: 'nota_de_venta'

    get "edit_temp_password", to: "users#edit_temp_password", as: :edit_temp_password
    patch "update_temp_password", to: "users#update_temp_password", as: :update_temp_password
  end


  # Inherits from Railsui::PageController#index
  # To overide, add your own page#index view or change to a new root
  # Visit the start page for Rails UI any time at /railsui/start
  root action: :sales_dashboard, controller: "admin/dashboards"

  devise_for :users, skip: [ :registrations ]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"

  get "not_authorized" => "application#not_authorized"

  if Rails.env.production?
    match "*unmatched", to: "application#render_not_found", via: :all
  end

  match "/", via: [ :options, :propfind, :post ], to: lambda { |_| [ 204, { "Content-Type" => "text/plain" }, [] ] }

  get "*unmatched_route", to: "application#render_not_found" unless Rails.env.development?
  post "*unmatched_route", to: "application#render_not_found" unless Rails.env.development?
  match "*unmatched_route", via: :all, to: "application#render_not_found" unless Rails.env.development?
end
