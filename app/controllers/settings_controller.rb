class SettingsController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def update
    flash[:notice] = "Paramètres mis à jour !"
    redirect_to settings_path
  end

  def edit_password
  end

  def update_password
    if current_user.authenticate(params[:user][:current_password]) # Vérifier l'ancien mot de passe
      if current_user.update(password_params)
        bypass_sign_in(current_user)
        redirect_to profile_path(current_user), notice: "Password successfully updated!"
      else
        flash.now[:alert] = "Failed to update password. Please check the errors."
        render :edit_password
      end
    else
      flash.now[:alert] = "Current password is incorrect."
      render :edit_password
    end
  end

  private

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
