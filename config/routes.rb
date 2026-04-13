Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  root "pages#home"

  resources :users, only: [ :index, :show ] do
    resource :profile, only: [ :edit, :update ], module: :users
  end

  resources :follows, only: [ :create, :destroy ] do
    member do
      patch :accept
      patch :reject
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
