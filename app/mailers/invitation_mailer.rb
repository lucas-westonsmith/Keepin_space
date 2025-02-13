class InvitationMailer < ApplicationMailer
  default from: "no-reply@keepin.space"

  def invite(invitation)
    @invitation = invitation
    @event = invitation.event

    mail(
      to: @invitation.email,
      subject: "You're invited to #{@event.title}!"
    )
  end
end
