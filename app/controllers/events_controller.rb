class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:public_index, :show]
  before_action :set_event, only: [:show, :edit, :update, :destroy, :join, :decline, :maybe, :pending, :remove, :save_note]
  before_action :authorize_event, only: [:edit, :update, :destroy]

  # Afficher tous les événements publics
  def public_index
    # Récupérer tous les événements publics triés par date croissante
    @events = Event.public_event.order(date: :asc)

    # Filtrer par recherche (sur titre, description, lieu et organisateur)
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @events = @events.where("title ILIKE ? OR description ILIKE ? OR location ILIKE ? OR user_id IN (?)", search_term, search_term, search_term, User.where("first_name ILIKE ? OR last_name ILIKE ?", search_term, search_term).pluck(:id))
    end

    # Filtrer par mois (si un mois est sélectionné)
    if params[:month].present?
      month_year = Date.parse(params[:month]) rescue nil
      if month_year
        @events = @events.where("DATE_PART('month', date) = ? AND DATE_PART('year', date) = ?", month_year.month, month_year.year)
      end
    end

    # Filtrer par statut d'invitation (seulement si l'utilisateur est connecté)
    if user_signed_in? && params[:status].present?
      case params[:status]
      when "accepted", "maybe", "pending", "declined"
        @events = @events.joins(:invitations).where(invitations: { user: current_user, status: params[:status] })
      when "none"
        # Corriger pour ne pas dupliquer les événements et ne montrer que ceux avec "No Status"
        @events = @events.left_outer_joins(:invitations)
                        .where("invitations.user_id IS NULL OR invitations.status IS NULL OR invitations.user_id != ?", current_user.id)
                        .group("events.id")
      end
    end
  end

  def user_events
    # Initialiser la liste des événements créés par l'utilisateur (statut "Accepted" par défaut)
    @created_events = current_user.events.order(date: :asc)

    # Initialiser la liste des événements auxquels l'utilisateur est invité (status: "accepted", "pending", "maybe")
    @invited_events = current_user.invitations.where(status: ["accepted", "pending", "maybe"]).map(&:event)

    # Fusionner les événements créés et invités en éliminant les doublons
    @joined_events = (@created_events + @invited_events).uniq

    # Filtrer par recherche (titre, description, lieu, organisateur)
    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      @joined_events = @joined_events.select do |event|
        event.title.downcase.include?(search_term) ||
        event.description.downcase.include?(search_term) ||
        event.location.downcase.include?(search_term) ||
        event.user.first_name.downcase.include?(search_term) ||
        event.user.last_name.downcase.include?(search_term)
      end
    end

    # Filtrer par mois (si un mois est sélectionné)
    if params[:month].present?
      begin
        # Tenter de convertir la valeur du mois en un objet Date
        month_year = Date.parse(params[:month])
        @joined_events = @joined_events.select do |event|
          event.date.month == month_year.month && event.date.year == month_year.year
        end
      rescue ArgumentError
        # Si la date n'est pas valide, on ignore le filtre de mois
      end
    end

    # Filtrer par statut (exclure les événements avec statut "declined")
    if params[:status].present?
      case params[:status]
      when "accepted", "maybe", "pending"
        @joined_events = @joined_events.select do |event|
          if @created_events.include?(event)
            # Si l'événement est créé par l'utilisateur, il a toujours le statut "Accepted"
            params[:status] == "accepted"
          else
            # Si l'événement est un événement invité, on vérifie l'invitation
            invitation = event.invitations.find_by(user: current_user)
            invitation && invitation.status == params[:status]
          end
        end
      when "none"
        # Filtrer les événements sans invitation ou avec un statut différent de "declined"
        @joined_events = @joined_events.reject do |event|
          invitation = event.invitations.find_by(user: current_user)
          invitation && invitation.status == "declined"
        end
      end
    end
  end

  # Afficher un événement spécifique
  def show
    @guests_with_account = @event.invitations.includes(:user)
                                 .where.not(user_id: nil)
                                 .map(&:user)
                                 .sort_by { |user| [(user.first_name || "").downcase, (user.last_name || "").downcase] }

    @guests_without_account = @event.invitations.where(user_id: nil)
                                 .sort_by { |inv| (inv.email || inv.phone_number.to_s).downcase }

    @sorted_invitations = @event.invitations.includes(:user)
                                .sort_by { |inv| [inv.user ? 0 : 1, (inv.user&.first_name || inv.email || "").downcase] }
    @note = current_user.notes_written.find_or_initialize_by(event_id: @event.id)
  end

  def save_note
    # Trouver ou initialiser une note pour l'utilisateur courant et l'événement courant
    @note = current_user.notes_written.find_or_initialize_by(event_id: @event.id)

    # Si target_id est nécessaire, assurez-vous qu'il est défini
    @note.target_id ||= current_user.id # Définir target_id sur l'utilisateur courant s'il est nil

    # Mettre à jour le contenu de la note
    if @note.update(content: params[:note][:content])
      redirect_to @event, notice: "Note saved successfully!"
    else
      redirect_to @event, alert: "Failed to save note."
    end
  end

  # Fichier calendrier Apple
  def download_ics
    event = Event.find(params[:id])
    ical = <<~ICS
      BEGIN:VCALENDAR
      VERSION:2.0
      PRODID:-//hacksw/handcal//NONSGML v1.0//EN
      BEGIN:VEVENT
      UID:#{event.id}@example.com
      DTSTAMP:#{Time.now.strftime("%Y%m%dT%H%M%S")}
      DTSTART:#{event.date.strftime("%Y%m%dT%H%M%S")}
      DTEND:#{event.end_date.strftime("%Y%m%dT%H%M%S")}
      SUMMARY:#{event.title} by #{event.user.first_name} #{event.user.last_name}
      DESCRIPTION:#{event.description} Event URL: #{event_invitation_url(event)}
      LOCATION:#{event.location}
      END:VEVENT
      END:VCALENDAR
    ICS

    send_data ical, type: 'text/calendar', disposition: 'attachment', filename: "#{event.title}.ics"
  end

  # Formulaire de création d'un événement
  def new
    @event = Event.new
  end

  # Créer un événement en BDD
# Créer un événement en BDD
def create
  @event = current_user.events.build(event_params)

  if @event.save
    # Ajouter une invitation pour l'utilisateur avec un statut 'accepted' après la création de l'événement
    @event.invitations.create(user_id: current_user.id, status: "accepted")

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

  # Rejoindre un événement
  def join
    invitation = @event.invitations.find_by(user_id: current_user.id)

    if invitation
      if invitation.status != "accepted"
        # If the invitation exists and its status is not "accepted", update it to "accepted"
        invitation.update(status: "accepted")
        flash[:notice] = "You have successfully joined the event!"
      else
        flash[:alert] = "You have already accepted this event."
      end
    else
      # If the invitation doesn't exist, create one with the "accepted" status
      @event.invitations.create(user_id: current_user.id, status: "accepted")
      flash[:notice] = "You have successfully joined the event!"
    end

    redirect_to @event
  end

  def decline
    @invitation = @event.invitations.find_by(user_id: current_user.id)
    if @invitation.present?
      @invitation.update(status: 'declined')
      flash[:notice] = "You have declined the event."
    else
      flash[:alert] = "You are not invited to this event."
    end
    redirect_to @event
  end

  def maybe
    @invitation = @event.invitations.find_by(user_id: current_user.id)
    if @invitation
      @invitation.update(status: 'maybe')
      flash[:notice] = "You marked the event as 'Maybe'."
    else
      flash[:alert] = "You are not invited to this event."
    end
    redirect_to @event
  end

  def pending
    @invitation = @event.invitations.find_by(user_id: current_user.id)
    if @invitation
      @invitation.update(status: 'pending')
      flash[:notice] = "You marked the event as 'Pending'."
    else
      flash[:alert] = "You are not invited to this event."
    end
    redirect_to @event
  end

  def remove
    @invitation = @event.invitations.find_by(user_id: current_user.id)
    if @invitation
      @invitation.destroy
      flash[:notice] = "Invitation removed."
    else
      flash[:alert] = "You are not invited to this event."
    end
    redirect_to @event
  end

  private

  # Récupérer l'event depuis l'ID en params
  def set_event
    @event = Event.find_by(id: params[:id])

    unless @event
      redirect_to events_path, alert: "Événement introuvable."
    end
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
