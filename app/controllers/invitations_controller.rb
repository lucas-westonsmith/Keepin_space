class InvitationsController < ApplicationController
  before_action :authenticate_user!, except: [:respond]
  before_action :set_event
  before_action :set_invitation, only: [:update, :destroy, :respond]

  # Create invitations for multiple emails and phones
  def create
    emails = params[:invitation][:email] || []  # Récupère les emails (peut être vide)
    phones = params[:invitation][:phone] || []  # Récupère les téléphones (peut être vide)

    # Pour chaque email et téléphone, crée une invitation
    emails.each_with_index do |email, index|
      @invitation = @event.invitations.build(email: email, phone: phones[index])

      # Vérifier si l'email correspond à un utilisateur existant
      existing_user = User.find_by(email: @invitation.email)
      @invitation.user = existing_user if existing_user

      if @invitation.save
        # Envoyer l'invitation par email si un email est présent
        send_invitation_email(@invitation) if @invitation.email.present?

        # Envoyer l'invitation par SMS si un numéro de téléphone est présent
        send_invitation_sms(@invitation) if @invitation.phone.present?

        # Créer une notification pour l'utilisateur invité (si enregistré)
        if @invitation.user
          Notification.create!(
            user: @invitation.user,
            event: @event,
            message: "You have been invited to #{@event.title}!"
          )
        end
      else
        # Si une invitation échoue, ajoute un message d'erreur et arrête la création
        flash[:alert] = "Failed to send invitation for #{email || phones[index]}"
        break
      end
    end

    redirect_to @event, notice: "Invitations sent successfully!"
  end

  # Update invitation status (Accept/Decline)
  def update
    if @invitation.update(status: params[:status])
      redirect_to @event, notice: "Invitation updated!"
    else
      redirect_to @event, alert: "Could not update invitation."
    end
  end

  # Accept or Decline an invitation via email link
  def respond
    if %w[accepted declined maybe].include?(params[:status])
      @invitation.update(status: params[:status])

      # Notify the event owner
      Notification.create!(
        user: @event.user,
        event: @event,
        message: "#{@invitation.email || @invitation.user&.email} has #{params[:status]} your invitation."
      )

      notice = "You have #{params[:status]} the invitation."
    else
      notice = "Invalid response."
    end

    redirect_to @event, notice: notice
  end

  # Remove an invitation
  def destroy
    @invitation.destroy
    redirect_to @event, notice: "Invitation removed."
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_invitation
    @invitation = @event.invitations.find(params[:id])
  end

  def invitation_params
    params.require(:invitation).permit(:email, :phone, :status)
  end

  def send_invitation_email(invitation)
    InvitationMailer.invite(invitation).deliver_later
  end

  def send_invitation_sms(invitation)
    # Utilise Twilio ou un autre service pour envoyer un SMS
    # Exemple:
    # TwilioClient.send_sms(invitation.phone, "You have been invited to #{@event.title}.")
  end
end
