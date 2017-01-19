Rails.application.routes.draw do
  root to: 'static#index'
  
  resources :static, only: :index
  resources :discussions, only: :index
  resources :follows, onyl: :index
end
