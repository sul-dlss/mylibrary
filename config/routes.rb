# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'summaries#index'
  resources :checkouts
  resources :requests
  resources :fines

  resource :feedback_form, path: 'feedback', only: %I[new create]
  get 'feedback' => 'feedback_forms#new'

  mount OkComputer::Engine, at: '/status'
end
