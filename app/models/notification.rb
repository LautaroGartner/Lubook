class Notification < ApplicationRecord
  ACTIONS = %w[comment reply like_post like_comment follow_request follow_accepted message].freeze

  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User"
  belongs_to :notifiable, polymorphic: true

  validates :action, presence: true, inclusion: { in: ACTIONS }

  scope :recent, -> { order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }

  after_create_commit :broadcast_updates!, unless: :message_action?

  def read?
    read_at.present?
  end

  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end

  def message
    case action
    when "comment"
      "#{actor.username} commented on your post."
    when "reply"
      "#{actor.username} replied to your comment."
    when "like_post"
      "#{actor.username} liked your post."
    when "like_comment"
      "#{actor.username} liked your comment."
    when "follow_request"
      "#{actor.username} sent you a follow request."
    when "follow_accepted"
      "#{actor.username} accepted your follow request."
    when "message"
      "#{actor.username} sent you a message."
    else
      "#{actor.username} interacted with you."
    end
  end

  def destination_path(view_context)
    case notifiable
    when Post
      view_context.post_path(notifiable)
    when Comment
      view_context.post_path(notifiable.post, anchor: view_context.dom_id(notifiable))
    when Follow
      view_context.user_path(actor)
    when Message
      view_context.conversation_path(notifiable.conversation)
    else
      view_context.root_path
    end
  end

  def actionable_follow_request_for?(user)
    action == "follow_request" &&
      recipient == user &&
      notifiable.is_a?(Follow) &&
      notifiable.pending?
  end

  private

  def message_action?
    action == "message"
  end

  def broadcast_updates!
    safe_broadcast_replace_to(
      [ recipient, :notifications ],
      target: "notifications_list_container",
      partial: "notifications/list",
      locals: { notifications: recipient.notifications.where.not(action: "message").recent }
    )

    safe_broadcast_replace_to(
      [ recipient, :notifications ],
      target: "notifications_badge",
      partial: "shared/notifications_badge",
      locals: { count: recipient.unread_notifications_count }
    )

    safe_broadcast_replace_to(
      [ recipient, :notifications ],
      target: "mobile_notifications_badge",
      partial: "shared/notifications_badge",
      locals: {
        count: recipient.unread_notifications_count,
        badge_id: "mobile_notifications_badge",
        badge_classes: "min-w-5 h-5 items-center justify-center rounded-full bg-rose-500 px-1.5 text-[11px] font-semibold text-white"
      }
    )

    safe_broadcast_replace_to(
      [ recipient, :notifications ],
      target: "mobile_menu_badge",
      partial: "shared/menu_badge",
      locals: {
        notifications_count: recipient.unread_notifications_count,
        chats_count: recipient.unread_chats_count
      }
    )
  end

  def safe_broadcast_replace_to(*streamables, **options)
    Turbo::StreamsChannel.broadcast_replace_to(*streamables, **options)
  rescue ArgumentError => error
    Rails.logger.warn("[Turbo broadcast skipped] #{error.class}: #{error.message}")
  end
end
