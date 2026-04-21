class NotificationsController < ApplicationController
  def index
    @notifications = current_user.notifications.where.not(action: "message").includes(:actor, :notifiable).recent
    @notifications.unread.update_all(read_at: Time.current)
  end

  def destroy
    notification = current_user.notifications.find(params[:id])
    notification.destroy
    redirect_to notifications_path, notice: "Notification cleared."
  end

  def clear
    current_user.notifications.where.not(action: "message").delete_all
    redirect_to notifications_path, notice: "Notifications cleared."
  end
end
