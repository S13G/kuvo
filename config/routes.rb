Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config

  ActiveAdmin.routes(self)
  get "up" => "rails/health#show", as: :rails_health_check

  post "/auth/google", to: "sessions#google"
  post "/auth/login", to: "sessions#login"
  post "auth/refresh", to: "sessions#refresh"

  resources :users, only: [] do
    collection do
      get :retrieve_favorite_products
      post :create
      post :verify_otp
      post :request_otp
      post :create_new_password
      post :verify_user
    end
  end

  resource :profile, only: [:show, :update]

  resources :products, only: [:index, :show] do
    collection do
      get :categories
      get :filter_type
      post ":id/favorites/add", to: "products#add_product_to_favorites"
      post ":product_id/favorites/remove", to: "products#remove_product_from_favorites"
    end
  end

  resources :suggestions, only: [:index]

  resources :carts, only: [] do
    collection do
      get :current, to: "carts#show"
      post :add_to_cart
      post :change_item_quantity
      post :remove_item
    end
  end

  resources :shipping_addresses

  resources :product_reviews, only: [:index, :create, :update]

  resources :orders, only: [:index, :show, :create] do
    collection do
      get "cancelled", to: "orders#cancelled_orders"
      get "completed", to: "orders#completed_orders"
      post :cancel
      get ":id/tracking_status", to: "orders#tracking_status"
    end
  end
end
