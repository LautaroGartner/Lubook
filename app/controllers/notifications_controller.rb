class NotificationsController < ApplicationController
  def index
    @notifications = current_user.notifications.where.not(action: "message").includes(:actor, :notifiable).recent
    @notifications.unread.update_all(read_at: Time.current)
  end

  def live
    include_list = ActiveModel::Type::Boolean.new.cast(params[:include_list])
    @notifications = current_user.notifications.where.not(action: "message").includes(:actor, :notifiable).recent
    @notifications.unread.update_all(read_at: Time.current) if include_list

    streams = [
      turbo_stream.replace(
        "notifications_badge",
        partial: "shared/notifications_badge",
        locals: { count: current_user.unread_notifications_count }
      )
    ]

    if include_list
      streams << turbo_stream.replace(
        "notifications_list_container",
        partial: "notifications/list",
        locals: { notifications: @notifications }
      )
    end

    render turbo_stream: streams
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
