class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = User.find(params[:id]) # Assure-toi que l'ID est bien passé
    @own_profile = @user == current_user

    unless @own_profile
      @common_events = current_user.events.where(id: @user.events.pluck(:id))
      @note = current_user.notes_written.find_or_initialize_by(target_id: @user.id)
    end
  end

  def save_note
    @note = current_user.notes_written.find_or_initialize_by(target_id: params[:id])
    if @note.update(content: params[:note][:content])
      redirect_to profile_path(params[:id]), notice: "Note saved!"
    else
      redirect_to profile_path(params[:id]), alert: "Failed to save note."
    end
  end
end
