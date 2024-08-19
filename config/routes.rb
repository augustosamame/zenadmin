Rails.application.routes.draw do
  if Rails.env.development? || Rails.env.test?
    mount Railsui::Engine, at: "/railsui"
  end

  get "admin/integrations", to: "page#integrations"
  get "admin/team", to: "page#team"
  get "admin/billing", to: "page#billing"
  get "admin/notifications", to: "page#notifications"
  get "admin/settings", to: "page#settings"
  get "admin/activity", to: "page#activity"
  get "admin/profile", to: "page#profile"
  get "admin/people", to: "page#people"
  get "admin/calendar", to: "page#calendar"
  get "admin/assignments", to: "page#assignments"
  get "admin/message", to: "page#message"
  get "admin/messages", to: "page#messages"
  get "admin/project", to: "page#project"
  get "admin/projects", to: "page#projects"
  get "admin/dashboard", to: "page#dashboard"
  get "pricing", to: "page#pricing"
  get "about", to: "page#about"

  #create a namespace for admin
  namespace :admin do
    resources :products
    get "pos", to: "pos#new"
    get "product_search", to: "products#product_search"

    resources :orders, only: [:new, :create, :update] do
      collection do
        post :save_as_draft
        get :load_draft
      end
    end
  end


  # Inherits from Railsui::PageController#index
  # To overide, add your own page#index view or change to a new root
  # Visit the start page for Rails UI any time at /railsui/start
  root action: :dashboard, controller: "page"

  devise_for :users
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
