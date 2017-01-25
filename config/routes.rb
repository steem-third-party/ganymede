Rails.application.routes.draw do
  root to: 'static#index'
  get :favicon, to: 'static#favicon'
  
  resources :static, only: :index
  resources :discussions, only: :index do
    collection do
      get :card
    end
  end
  resources :follows, only: :index
  resources :accounts, only: :index
end
