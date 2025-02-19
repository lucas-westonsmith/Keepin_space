class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:public_index, :show]
  before_action :set_event, only: [:show, :edit, :update, :destroy, :join, :decline, :maybe, :pending, :remove, :save_note, :create_post, :create_poll]
  before_action :authorize_event, only: [:edit, :update, :destroy]

  def public_index
    # Récupérer tous les événements publics triés par date croissante
    @events = Event.public_event.order(date: :asc)

    # Inclure les événements passés seulement si la case "Show also past events" est cochée
    if params[:show_past] == "true"
      # Aucun filtrage, on garde tous les événements, passés et à venir
    else
      # Sinon, afficher uniquement les événements à venir
      @events = @events.where("date >= ?", Date.today)
    end

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

    # Filtrer les événements passés si la case "Show Past" est cochée
    if params[:show_past] == "true"
      # Aucune restriction sur la date, on garde les événements passés et à venir
    else
      # Filtrer pour ne garder que les événements futurs
      @joined_events = @joined_events.select { |event| event.date >= Date.today }
    end
  end

  # Afficher un événement spécifique
  def show
    filter = params[:filter] || "all" # Filtre par défaut : tout afficher

    # Liste des invités avec un compte
    @guests_with_account = @event.invitations.includes(:user)
                                         .where.not(user_id: nil)
                                         .map(&:user)
                                         .sort_by { |user| [(user.first_name || "").downcase, (user.last_name || "").downcase] }

    # Liste des invités sans compte
    @guests_without_account = @event.invitations.where(user_id: nil)
                                         .sort_by { |inv| (inv.email || inv.phone_number.to_s).downcase }

    # Tri général des invitations
    @sorted_invitations = @event.invitations.includes(:user)
                                            .sort_by { |inv| [inv.user ? 0 : 1, (inv.user&.first_name || inv.email || "").downcase] }

    # Appliquer le filtre
    case filter
    when "attending"
      @sorted_invitations = @sorted_invitations.select { |inv| inv.status == 'accepted' }
    when "contacts_attending"
      # Appliquer un filtre sur les contacts uniquement, et exclure l'organisateur
      @sorted_invitations = @sorted_invitations.select { |inv| inv.user && current_user.contacts.include?(inv.user) && inv.user != @event.user }
    when "not_attending"
      @sorted_invitations = @sorted_invitations.reject { |inv| inv.status == 'accepted' }
    else
      # "all" ou aucun filtre spécifié
      @sorted_invitations = @sorted_invitations.reject { |inv| inv.user == @event.user } # Exclure l'organisateur ici également
    end

    @note = current_user.notes_written.find_or_initialize_by(event_id: @event.id)
    @contacts = current_user.contacts
    @posts = @event.posts.order(created_at: :desc)
    @polls = @event.polls
    @new_post = Post.new
    @new_poll = Poll.new
  end

  def create_post
    @post = @event.posts.build(post_params)
    @post.user = current_user
    if @post.save
      redirect_to @event, notice: 'Post created successfully!'
    else
      redirect_to @event, alert: 'Failed to create post.'
    end
  end

  def create_poll
    @new_poll = @event.polls.new(poll_params)

    if @new_poll.save
      # Création manuelle des options de sondage à partir des paramètres
      poll_options_params.each do |option_params|
        @new_poll.poll_options.create(option_params)
      end

      redirect_to @event, notice: "Poll created successfully!"
    else
      render :new
    end
  end

  def search_contacts
    query = params[:query].to_s.strip.downcase
    return render json: [] if query.blank?

    terms = query.split  # Découpe la recherche en plusieurs mots (ex: "Lucas S")

    if terms.length > 1
      # Si plusieurs termes sont tapés, chercher prénom et nom ensemble
      contacts = current_user.contacts.where(
        "LOWER(first_name) LIKE ? AND LOWER(last_name) LIKE ?",
        "#{terms[0]}%", "#{terms[1]}%"
      )
    else
      # Recherche normale sur prénom ou nom si un seul mot
      contacts = current_user.contacts.where(
        "LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ?",
        "#{query}%", "#{query}%"
      )
    end

    render json: contacts.map { |c| { id: c.id, name: "#{c.first_name} #{c.last_name}" } }
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

  def post_params
    params.require(:post).permit(:content, :image)
  end

  def poll_params
    # Permet le paramètre `poll_options` comme un tableau d'objets
    params.require(:poll).permit(:question, poll_options: [:content])
  end

  def poll_options_params
    # Vérifie si `poll_options` existe, sinon retourne un tableau vide
    return [] if params[:poll][:poll_options].nil?

    # Permet de récupérer les options de sondage
    params[:poll][:poll_options].map { |option| option.permit(:content) }
  end

end
