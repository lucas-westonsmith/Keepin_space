class SettingsController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def update
    flash[:notice] = "Paramètres mis à jour !"
    redirect_to settings_path
  end
end
