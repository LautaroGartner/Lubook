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
        "chat_badge",
        partial: "shared/chat_badge",
        locals: { count: current_user.unread_chats_count }
      ),
      turbo_stream.replace(
        "mobile_chat_badge",
        partial: "shared/chat_badge",
        locals: {
          count: current_user.unread_chats_count,
          badge_id: "mobile_chat_badge",
          badge_classes: "min-w-5 h-5 items-center justify-center rounded-full bg-stone-900 px-1.5 text-[11px] font-semibold text-white"
        }
      ),
      turbo_stream.replace(
        "notifications_badge",
        partial: "shared/notifications_badge",
        locals: { count: current_user.unread_notifications_count }
      ),
      turbo_stream.replace(
        "mobile_notifications_badge",
        partial: "shared/notifications_badge",
        locals: {
          count: current_user.unread_notifications_count,
          badge_id: "mobile_notifications_badge",
          badge_classes: "min-w-5 h-5 items-center justify-center rounded-full bg-rose-500 px-1.5 text-[11px] font-semibold text-white"
        }
      ),
      turbo_stream.replace(
        "mobile_menu_badge",
        partial: "shared/menu_badge",
        locals: {
          notifications_count: current_user.unread_notifications_count,
          chats_count: current_user.unread_chats_count
        }
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
