Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config

  ActiveAdmin.routes(self)
  get "up" => "rails/health#show", as: :rails_health_check

  post "/auth/google", to: "sessions#google"
  post "/auth/login", to: "sessions#login"
  post "auth/refresh", to: "sessions#refresh"

  resources :users, only: [] do
    collection do
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
      post "/favorites/add", to: "products#add_product_to_users_favorites"
      post "/favorites/remove", to: "products#remove_product_from_users_favorites"
    end
  end

  resources :suggestions, only: [:index]

  resources :carts, only: [:show] do
    collection do
      post :add_to_cart
      post :remove_from_cart
    end
  end
end
