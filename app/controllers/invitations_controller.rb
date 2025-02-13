class InvitationsController < ApplicationController
  before_action :authenticate_user!, except: [:respond]
  before_action :set_event
  before_action :set_invitation, only: [:update, :destroy, :respond]

  # Create an invitation
  def create
    @invitation = @event.invitations.build(invitation_params)

    # Check if the invited email belongs to an existing user
    existing_user = User.find_by(email: @invitation.email)
    @invitation.user = existing_user if existing_user

    if @invitation.save
      send_invitation_email(@invitation) if @invitation.email.present?

      # Create notification for invited user
      if @invitation.user
        Notification.create!(
          user: @invitation.user,
          event: @event,
          message: "You have been invited to #{@event.title}!"
        )
      end

      redirect_to @event, notice: "Invitation sent successfully!"
    else
      redirect_to @event, alert: "Failed to send invitation."
    end
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
    params.require(:invitation).permit(:email, :phone_number, :status)
  end

  def send_invitation_email(invitation)
    InvitationMailer.invite(invitation).deliver_later
  end
end
