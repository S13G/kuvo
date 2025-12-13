Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "/auth/:provider/callback", to: "sessions#google"
  get "/auth/failure", to: redirect("/")
  post "/auth/login", to: "sessions#login"

  resources :users do
    collection do
      post :create
      post :verify_otp
      post :request_otp
      post :create_new_password
      post :verify_user
    end
  end
end
