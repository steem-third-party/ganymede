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
end
