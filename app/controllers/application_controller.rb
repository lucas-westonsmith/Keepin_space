class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_user_data
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def set_user_data
    if current_user
      session[:user_id] = current_user.id
      cookies.signed[:user_id] = {
        value: current_user.id,
        httponly: false, # Désactivé temporairement pour vérifier
        expires: 1.hour.from_now
      }

      Rails.logger.info "✅ Session user_id stockée : #{session[:user_id]}"
      Rails.logger.info "🍪 Cookie user_id défini : #{cookies.signed[:user_id]}"
    end
  end

  protected

  # Autoriser les nouveaux champs pour Devise
  def configure_permitted_parameters
    added_attrs = [:first_name, :last_name, :date_of_birth, :phone_number, :profession, :bio, :hobbies, :avatar,
                   :secondary_email, :linkedin, :facebook, :instagram,
                   :twitter, :tiktok, :github]
    devise_parameter_sanitizer.permit(:sign_up, keys: added_attrs)
    devise_parameter_sanitizer.permit(:account_update, keys: added_attrs)
  end
end
