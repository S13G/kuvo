Rails.application.routes.draw do
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
end
