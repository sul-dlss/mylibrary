# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'sessions#index'

  # business + law use libcal, not oncehub, so we override their routes:
  get 'schedule/pickup/BUSINESS' => 'schedules#libcal_pickup', id: 'BUSINESS'
  get 'schedule/pickup/LAW' => 'schedules#libcal_pickup', id: 'LAW'

  get 'schedule/visit/:id' => 'schedules#show', as: 'schedule_visit', type: :visit
  get 'schedule/pickup/:id' => 'schedules#show', as: 'schedule_pickup', type: :pickup

  # legacy url support
  get 'schedule/eal' => 'schedules#show', id: 'EAST-ASIA', type: :visit
  get 'schedule/green' => 'schedules#show', id: 'GREEN', type: :visit
  get 'schedule/spec' => 'schedules#show', id: 'SPEC-COLL', type: :visit

  get 'schedule/green_pickup' => 'schedules#show', id: 'GREEN', type: :pickup
  get 'schedule/eal_pickup' => 'schedules#show', id: 'EAST-ASIA', type: :pickup
  get 'schedule/miller_pickup' => 'schedules#show', id: 'HOPKINS', type: :pickup

  get 'schedule/business_pickup' => 'schedules#libcal_pickup', id: 'BUSINESS'
  get 'schedule/law_pickup' => 'schedules#libcal_pickup', id: 'LAW'

  resources :summaries
  resources :checkouts
  resources :requests do
    member do
      get 'cdl_waitlist_position'
    end
  end
  resources :fines
  resources :payments, only: :index
  resources :renewals, only: %I[create] do
    post 'all_eligible', on: :collection
  end

  resource :contact_forms, path: 'contact', only: %I[new create]
  get 'contact' => 'contact_forms#new'

  resource :feedback_form, path: 'feedback', only: %I[new create]
  get 'feedback' => 'feedback_forms#new'

  get '/sessions/login_by_sunetid', to: 'sessions#login_by_sunetid', as: :login_by_sunetid
  post '/sessions/login_by_library_id', to: 'sessions#login_by_library_id', as: :login_by_library_id
  get '/login', to: 'sessions#form', as: :login
  get '/logout', to: 'sessions#destroy', as: :logout

  get '/reset_pin', to: 'reset_pins#index'
  post '/reset_pin', to: 'reset_pins#reset'
  get '/change_pin/:token', to: 'reset_pins#change_form', as: :change_pin_with_token
  post '/change_pin', to: 'reset_pins#change'

  resources :payments, only: %I[create]
  post '/payments/accept', to: 'payments#accept'
  post '/payments/cancel', to: 'payments#cancel'

  get '/unavailable', to: 'services#unavailable'

  mount OkComputer::Engine, at: '/status'
end
