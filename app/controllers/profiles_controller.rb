class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = User.find(params[:id]) # Assure-toi que l'ID est bien passé
    @own_profile = @user == current_user

    unless @own_profile
      @common_events = current_user.events.where(id: @user.events.pluck(:id))
      @note = current_user.notes_written.find_or_initialize_by(target_id: @user.id)

      # Vérifie si l'utilisateur est déjà un contact
      @is_contact = Contact.exists?(user_id: current_user.id, contact_id: @user.id)
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

  # Action pour ajouter un contact
  def add_contact
    @user = User.find(params[:id])

    # Vérifie si l'utilisateur est déjà un contact dans la table `contacts`
    unless current_user.contacts.exists?(id: @user.id)
      current_user.contacts_as_user.create(contact: @user)
      flash[:notice] = "You have added #{@user.first_name} to your contacts."
    else
      flash[:alert] = "This user is already in your contacts."
    end

    redirect_to profile_path(@user)
  end

  def index
    # Récupère tous les contacts de l'utilisateur connecté
    @contacts = current_user.contacts
  end
end
