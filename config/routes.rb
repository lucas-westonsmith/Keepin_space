Rails.application.routes.draw do
  get 'settings/show'
  get 'settings/update'

  root to: "pages#home"

  devise_for :users, controllers: {
    passwords: "devise/passwords"
  }

  resources :events do
    member do
      post "join"
      post "leave"
    end

    resources :invitations, only: [:create, :update, :destroy] do
      member do
        get 'respond/:status', to: 'invitations#respond', as: :respond
      end
    end
  end

  resources :notifications, only: [:index, :update]
  resources :messages, only: [:index, :show, :create]  # ✅ Messages
  resources :profiles, only: [:show]  # ✅ Profil avec ID pour afficher les autres utilisateurs
  resource :settings, only: [:show, :update]  # ✅ Paramètres

  get "/discover", to: "pages#discover", as: :discover  # ✅ Page Discover
  get "/pricing", to: "pages#pricing", as: :pricing  # ✅ Page Pricing
  post "/profiles/:id/notes", to: "profiles#save_note", as: :profile_notes
end
