# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'sessions#index'
  resources :summaries
  resources :checkouts
  resources :requests
  resources :fines

  resource :feedback_form, path: 'feedback', only: %I[new create]
  get 'feedback' => 'feedback_forms#new'

  get '/sessions/login_by_sunetid', to: 'sessions#login_by_sunetid', as: :login_by_sunetid
  post '/sessions/login_by_library_id', to: 'sessions#login_by_library_id', as: :login_by_library_id
  get '/login', to: 'sessions#form', as: :login
  get '/logout', to: 'sessions#destroy', as: :logout

  mount OkComputer::Engine, at: '/status'
end
