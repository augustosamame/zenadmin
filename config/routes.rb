require "sidekiq/web"

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"
  mount Shrine.presign_endpoint(:cache) => "/s3/params"

  if Rails.env.development? || Rails.env.test?
    mount Railsui::Engine, at: "/railsui"
  end

  get "pricing", to: "page#pricing"
  get "about", to: "page#about"

  # create a namespace for admin
  namespace :admin do
    resources :products do
      resources :media, module: :admin
      get "search", on: :collection
      get "combo_products_show", on: :member
    end

    get "kardex", to: "kardex#show"
    get "fetch_kardex_movements", to: "kardex#fetch_kardex_movements"

    resources :product_categories do
      resources :media, module: :admin
    end

    resources :orders, only: [ :index, :new, :create, :update ] do
      collection do
        get "pos"
      end
    end
    resources :payment_methods
    resources :users
    get "sellers", to: "users#sellers"
    resources :customers
    post "pos_create_customer", to: "users#create_customer"
    get "search_dni", to: "customers#search_dni"

    resources :warehouses
    patch "/set_current_warehouse", to: "warehouses#set_current_warehouse"
    get "inventory", to: "inventory/inventory#show"

    namespace :inventory do
      resources :periodic_inventories, only: [:index, :new, :create, :show]
    end

    resources :stock_transfers do
      member do
        patch :set_to_in_transit
        patch :set_to_complete
      end
    end
    resources :in_transit_stocks

    resources :combo_products

    resources :cashier_shifts do
      member do
        patch :close
      end
    end

    resources :cashier_transactions, only: [ :new, :create ]
    resources :commissions, only: [ :index, :show ]

    get "dashboard", to: "page#dashboard"
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
  root action: :dashboard, controller: "admin/page"

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
end
