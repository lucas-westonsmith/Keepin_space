class Event < ApplicationRecord
  belongs_to :user
  has_many :invitations, dependent: :destroy
  has_many :attendees, through: :invitations, source: :user
  has_many :notes, as: :target, dependent: :destroy
  has_many :polls, dependent: :destroy  # Ajoutez cette ligne pour les sondages
  has_many :posts, dependent: :destroy  # Ajoutez cette ligne pour les publications

  enum visibility: { public_event: 0, private_event: 1, invite_only: 2 }
  # Ajoutez cette ligne pour permettre le contrôle des posts sur le mur
  attribute :can_post_on_wall, :boolean, default: false

  # Nom de l'organisateur
  def organizer_name
    user.present? ? "#{user.first_name} #{user.last_name}" : "Unknown Organizer"
  end

  # Nombre de participants
  def attendees_count
    invitations.where(status: "accepted").count
  end

  # Nombre de contacts présents à l'événement
  def contacts_attending_count(current_user)
    return 0 unless current_user

    contacts_ids = current_user.contacts.pluck(:id)
    invitations.where(status: "accepted", user_id: contacts_ids).count
  end

  # Nombre de personnes déjà rencontrées à l'événement
def people_you_ever_met_count(current_user)
  return 0 unless current_user

  # Récupère les événements passés où l'utilisateur a accepté l'invitation
  past_event_ids = current_user.invitations.joins(:event)
                                      .where(status: "accepted")
                                      .where("events.date < ?", DateTime.now)
                                      .pluck(:event_id)

  # Récupère les invités acceptés dans ces événements passés
  already_met_ids = Invitation.where(event_id: past_event_ids, status: "accepted")
                              .where.not(user_id: current_user.id)
                              .pluck(:user_id)
                              .uniq

  # Récupère les invités acceptés pour l'événement actuel
  current_event_attendees = invitations.where(status: "accepted").pluck(:user_id)

  # Intersection entre les personnes déjà rencontrées et les invités de l'événement actuel
  (already_met_ids & current_event_attendees).count
end

  # Méthode pour obtenir le statut d'un utilisateur
  def user_status(current_user)
    return '👑 Organizer' if user == current_user

    invitation = invitations.find_by(user: current_user)
    if invitation
      case invitation.status
      when 'accepted'
        return '✅ Accepted'
      when 'pending'
        return '⌛ Pending'
      when 'declined'
        return '❌ Declined'
      when 'maybe'
        return '🤔 Maybe'
      end
    end

    '❓ No Status'
  end
end
