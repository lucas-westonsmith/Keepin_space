class NotificationsController < ApplicationController
  before_action :authenticate_user!

  # Show all notifications
  def index
    @notifications = current_user.notifications.order(created_at: :desc)
  end

  # Fix: Ensure update works with PATCH request
  def update
    notification = current_user.notifications.find(params[:id])
    notification.update(read_at: Time.current) # Marquer comme lu
    redirect_to notifications_path, notice: "Notification marked as read."
  end
end
