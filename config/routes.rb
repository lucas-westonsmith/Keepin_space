Rails.application.routes.draw do
  get 'settings/show'
  get 'settings/update'

  root to: "pages#home"

  devise_for :users

  # Route pour afficher les événements publics
  get '/events/public', to: 'events#public_index', as: :public_events
  # Route pour afficher les événements de l'utilisateur
  get '/events/user_events', to: 'events#user_events', as: :user_events
  resources :events do
    member do
      post "join"
      post "decline"
      post "maybe"   # Ajouter cette route pour l'option "Maybe"
      post "pending" # Ajouter cette route pour l'option "Pending"
      post "remove"  # Ajouter cette route pour l'option "Remove"
      get :download_ics
    end

    resources :invitations, only: [:create, :update, :destroy] do
      member do
        get 'respond/:status', to: 'invitations#respond', as: :respond
      end
    end
  end

  resources :notifications, only: [:index, :update]
  resources :messages, only: [:index, :show, :create]
  resource :settings, only: [:show, :update]

  resources :profiles, only: [:show] do
    post 'add_contact', on: :member  # Cette ligne crée la route pour l'ajout de contact
  end

  get "/discover", to: "pages#discover", as: :discover
  get "/pricing", to: "pages#pricing", as: :pricing
  get 'contacts', to: 'profiles#index', as: 'contacts'
  post "/profiles/:id/notes", to: "profiles#save_note", as: :profile_notes
  post "/events/:id/notes", to: "events#save_note", as: :event_notes
  get "/settings/password", to: "settings#edit_password", as: :edit_password
  patch "/settings/password", to: "settings#update_password"
end
