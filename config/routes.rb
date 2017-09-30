Rails.application.routes.draw do
  root to: 'static#index'
  get :favicon, to: 'static#favicon'
  get :mvests, to: 'static#mvests'
  
  resources :static, only: :index
  resources :discussions, only: :index do
    collection do
      get :card
    end
  end
  resources :follows, only: :index
  resources :accounts, only: :index
  resources :transfers, only: :index
  resources :tickers, param: :pair, only: [:index, :show]
  resources :charts, param: :account_name, only: [:index, :show] do
    member do
      get :net_transfers
      get :day_of_the_week
    end
  end
end
