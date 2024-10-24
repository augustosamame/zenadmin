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

  # create a namespace for admin
  namespace :admin do
    resources :products do
      resources :media, module: :admin
      get "search", on: :collection
      get "combo_products_show", on: :member
    end

    resources :product_categories, except: [:show] do
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
      end
      collection do
        get "pos"
      end
    end
    resources :payment_methods
    resources :users do
      member do
        get "loyalty_info"
        patch "update_contact_info"
      end
    end
    get "sellers", to: "users#sellers"

    resources :user_attendance_logs, only: [ :index, :new, :create, :edit, :update ] do
      collection do
        get "check_attendance_status"
        post "seller_checkout"
        get "seller_checkin_status"
        get "location_sellers"
        get "seller_attendance_report"
        get "location_attendance_report"
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
      resources :periodic_inventories, only: [ :index, :new, :create, :show ]
    end

    resources :stock_transfers do
      collection do
        get "index_stock_adjustments"
      end
      member do
        patch :set_to_in_transit
        get :initiate_receive
        post :execute_receive
      end
    end
    resources :in_transit_stocks

    resources :combo_products
    resources :discount_products
    resources :discounts do
      get 'matching_products', on: :collection
    end
    resources :cashier_shifts do
      member do
        patch :close
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
    resources :product_categories

    get "sales_dashboard", to: "dashboards#sales_dashboard"
    post "dashboards/set_location", to: "dashboards#set_location"

    get 'reports/form', to: 'reports#reports_form'
    post 'reports/generate', to: 'reports#generate'
    get "reports/cash_flow", to: "reports#cash_flow"
    get "reports/inventory_out", to: "reports#inventory_out"
    get "reports/consolidated", to: "reports#consolidated"


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
