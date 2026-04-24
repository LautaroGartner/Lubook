Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  namespace :api do
    namespace :v1 do
      namespace :auth do
        post :sign_in, to: "sessions#create"
        delete :sign_out, to: "sessions#destroy"
      end

      get :me, to: "users#show"
      get :feed, to: "feed#index"
      resources :conversations, only: [ :index, :show, :create ] do
        member do
          patch :read
        end
        resources :messages, only: :create
      end
      resources :notifications, only: [ :index, :destroy ] do
        collection do
          delete :clear
        end
      end
      resources :posts, only: [ :show, :create ] do
        resources :comments, only: [ :create ]
        resource :like, only: [ :create, :destroy ], module: :posts
      end

      resources :comments, only: [] do
        resource :like, only: [ :create, :destroy ], module: :comments
      end
    end
  end

  root "pages#home"

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

  resources :conversations, only: [ :index, :show, :create ] do
    member do
      get :live
      get :presence
      patch :read
    end
    resources :messages, only: :create
  end

  get "/chat/:username", to: "conversations#show", as: :chat
  get "/chat/:username/live", to: "conversations#live", as: :live_chat
  get "/chat/:username/presence", to: "conversations#presence", as: :presence_chat
  patch "/chat/:username/read", to: "conversations#read", as: :read_chat

  resources :notifications, only: [ :index, :destroy ] do
    collection do
      get :live
      delete :clear
    end
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
