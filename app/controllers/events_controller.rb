class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_event, only: [:show, :edit, :update, :destroy, :join, :leave]
  before_action :authorize_event, only: [:edit, :update, :destroy]

  # Afficher tous les événements
  def index
    @events = Event.all.order(date: :asc)
  end

  # Afficher un événement spécifique
  def show
  end

  # Formulaire de création d'un événement
  def new
    @event = Event.new
  end

  # Créer un événement en BDD
  def create
    @event = current_user.events.build(event_params)
    if @event.save
      redirect_to @event, notice: "Événement créé avec succès !"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # Formulaire d'édition d'un événement
  def edit
  end

  # Mettre à jour un événement en BDD
  def update
    if @event.update(event_params)
      redirect_to @event, notice: "Événement mis à jour !"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Supprimer un événement
  def destroy
    @event.destroy
    redirect_to events_path, notice: "Événement supprimé."
  end

  # ✅ Rejoindre un événement
  def join
    if @event.invitations.exists?(user_id: current_user.id)
      flash[:alert] = "Vous êtes déjà invité à cet événement."
    else
      @event.invitations.create(user_id: current_user.id, status: "accepted")
      flash[:notice] = "Vous avez rejoint l'événement avec succès !"
    end
    redirect_to @event
  end

  # ✅ Quitter un événement
  def leave
    invitation = @event.invitations.find_by(user_id: current_user.id)
    if invitation
      invitation.destroy
      flash[:notice] = "Vous avez quitté l'événement."
    else
      flash[:alert] = "Vous ne participez pas à cet événement."
    end
    redirect_to @event
  end

  private

  # Récupérer l'event depuis l'ID en params
  def set_event
    @event = Event.find(params[:id])
  end

  # Vérifier que l'user est bien le créateur de l'event
  def authorize_event
    redirect_to events_path, alert: "Action non autorisée" unless @event.user == current_user || current_user.admin?
  end

  # Définir les params autorisés
  def event_params
    params.require(:event).permit(:title, :description, :date, :end_date, :location, :sub_location, :visibility)
  end
end
