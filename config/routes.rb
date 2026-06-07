Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Logged-in landing page (the store dashboard)
  root "dashboard#show"

  resources :products

  resources :orders, only: [ :index ] do
    member { patch :ship }
  end

  # Public storefront (no login; tenant comes from the URL slug)
  scope path: "s", module: "storefront", as: "storefront" do
    get ":store_slug", to: "stores#show", as: :store
    get ":store_slug/checkout/:product_id", to: "orders#new", as: :store_checkout
    post ":store_slug/orders", to: "orders#create", as: :store_orders
  end

  # Payment webhooks (verified, no CSRF/login)
  post "payments/ecpay/callback", to: "payments/ecpay#callback", as: :payments_ecpay_callback
  post "payments/stripe/webhook", to: "payments/stripe#webhook", as: :payments_stripe_webhook

  # JSON API (JWT auth)
  namespace :api do
    namespace :v1 do
      post "login", to: "sessions#create"
      post "refresh", to: "sessions#refresh"
      delete "logout", to: "sessions#destroy"
      delete "logout_all", to: "sessions#destroy_all"
      resources :products, only: %i[index show]
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
