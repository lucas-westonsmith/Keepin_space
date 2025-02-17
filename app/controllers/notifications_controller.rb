class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications.order(created_at: :desc)
  end

  def update
    @notification = current_user.notifications.find(params[:id])
    @notification.update(read_at: Time.current)

    respond_to do |format|
      format.json { render json: { success: true, notification_id: @notification.id } }
    end
  end
end
