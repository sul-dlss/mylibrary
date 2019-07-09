# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'summaries#index'
  resources :checkouts
  resources :requests

  mount OkComputer::Engine, at: '/status'
end
