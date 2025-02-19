Rails.application.routes.draw do
  root to: "pages#home"

  devise_for :users

  # Routes pour les événements
  get '/events/public', to: 'events#public_index', as: :public_events
  get '/events/user_events', to: 'events#user_events', as: :user_events

  resources :events do
    member do
      post "join"
      post "decline"
      post "maybe"
      post "pending"
      post "remove"
      get :download_ics
      post :create_post  # Ajout pour créer un post
      post :create_poll  # Ajout pour créer un sondage
    end

    collection do
      get 'search_contacts'  # Accessible sans ID d'événement
    end

    resources :invitations, only: [:create, :update, :destroy] do
      member do
        get 'respond/:status', to: 'invitations#respond', as: :respond
      end
    end
  end

  # Routes pour les notifications et messages
  resources :notifications, only: [:index, :update]
  resources :messages, only: [:index, :show, :create]

  # Routes pour les paramètres
  resource :settings, only: [:show, :update] do
    get "password", to: "settings#edit_password", as: :edit_password
    patch "password", to: "settings#update_password"
  end

  # Routes pour les profils et contacts
  resources :profiles, only: [:show] do
    post 'add_contact', on: :member
  end
  get 'contacts', to: 'profiles#index', as: 'contacts'
  post "/profiles/:id/notes", to: "profiles#save_note", as: :profile_notes

  # Routes pour les notes sur les événements
  post "/events/:id/notes", to: "events#save_note", as: :event_notes

  # Pages statiques
  get "/discover", to: "pages#discover", as: :discover
  get "/pricing", to: "pages#pricing", as: :pricing
end
