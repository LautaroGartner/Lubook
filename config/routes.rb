Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  root "pages#home"

  resources :users, only: [ :index, :show ] do
    resource :profile, only: [ :edit, :update ], module: :users
  end

  resources :users, only: [ :index, :show ] do
    resource :profile, only: [ :edit, :update ], module: :users
    member do
      get :followers
      get :following
    end
  end

  resources :posts, only: [ :create, :show, :edit, :update, :destroy ] do
    resources :comments, only: [ :create, :destroy ], shallow: true
    resource  :like, only: [ :create, :destroy ], module: :posts
  end

  resources :comments, only: [] do
    resource :like, only: [ :create, :destroy ], module: :comments
  end

  resources :follows, only: [ :create, :destroy ] do
    member do
      patch :accept
      patch :reject
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
