class Event < ApplicationRecord
  belongs_to :user
  has_many :invitations, dependent: :destroy
  has_many :attendees, through: :invitations, source: :user

  enum visibility: { public_event: 0, private_event: 1, invite_only: 2 }

  def organizer_name
    user.present? ? "#{user.first_name} #{user.last_name}" : "Unknown Organizer"
  end

  def attendees_count
    invitations.where(status: "accepted").count
  end

  def contacts_attending_count(current_user)
    return 0 unless current_user

    contacts_ids = current_user.contacts.pluck(:id)
    invitations.where(status: "accepted", user_id: contacts_ids).count
  end

  def people_you_ever_met_count(current_user)
    return 0 unless current_user

    past_event_ids = current_user.invitations.joins(:event)
                                        .where(status: "accepted")
                                        .where("events.date < ?", DateTime.now)
                                        .pluck(:event_id)

    already_met_ids = Invitation.where(event_id: past_event_ids, status: "accepted")
                                .where.not(user_id: current_user.id)
                                .pluck(:user_id)
                                .uniq

    current_event_attendees = invitations.where(status: "accepted").pluck(:user_id)

    (already_met_ids & current_event_attendees).count
  end
end
