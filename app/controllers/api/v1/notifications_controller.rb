class Api::V1::NotificationsController < Api::V1::BaseController
  include Api::V1::Serialization

  def index
    notifications = current_api_user.notifications
                                    .where.not(action: "message")
                                    .includes(:actor, :notifiable)
                                    .recent
    notifications.unread.update_all(read_at: Time.current)

    render json: {
      notifications: notifications.map { |notification| serialize_notification(notification, viewer: current_api_user) }
    }
  end

  def destroy
    notification = current_api_user.notifications.find(params[:id])
    notification.destroy
    render json: {}
  end

  def clear
    current_api_user.notifications.where.not(action: "message").delete_all
    render json: {}
  end
end
