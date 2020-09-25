# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'sessions#index'
  get 'schedule/eal' => 'schedules#show', oncehub_id: 'StanfordLibrariesEastAsiaLibraryEntry'
  get 'schedule/green' => 'schedules#show', oncehub_id: 'StanfordLibrariesGreenEntry'
  get 'schedule/spec' => 'schedules#show', oncehub_id: 'StanfordLibrariesVisitSpecialCollections'
  get 'schedule/green_pickup' => 'schedules#show', oncehub_id: 'StanfordLibrariesPagingPickupGreenLibrary'
  get 'schedule/eal_pickup' => 'schedules#show', oncehub_id: 'StanfordLibrariesPagingPickupEastAsiaLibrary'
  get 'schedule/business_pickup' => 'schedules#business_pickup'

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
