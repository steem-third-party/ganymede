Rails.application.routes.draw do
  root to: 'static#index'
  get :favicon, to: 'static#favicon'
  
  resources :static, only: :index
  resources :discussions, only: :index
  resources :follows, only: :index
end
