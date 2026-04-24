module Api::V1::Serialization
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.url_helpers
  end

  def serialize_user(user, viewer:)
    {
      id: user.id,
      username: user.username,
      email: viewer == user ? user.email : nil,
      display_name: user.profile&.display_name,
      bio: user.profile&.bio,
      location: user.profile&.location,
      avatar_url: attachment_url(user.profile&.avatar),
      followers_count: user.followers.count,
      following_count: user.following.count,
      unread_notifications_count: viewer == user ? user.unread_notifications_count : nil,
      unread_chats_count: viewer == user ? user.unread_chats_count : nil,
      share_last_seen: viewer == user ? user.share_last_seen : nil,
      share_read_receipts: viewer == user ? user.share_read_receipts : nil
    }.compact
  end

  def serialize_post(post, viewer:)
    {
      id: post.id,
      body: post.body,
      created_at: post.created_at.iso8601,
      updated_at: post.updated_at.iso8601,
      edited: post.updated_at > post.created_at + 1.minute,
      image_url: attachment_url(post.image),
      comments_count: post.comments.size,
      likes_count: post.likes.size,
      liked_by_current_user: post.liked_by?(viewer),
      author: serialize_user(post.user, viewer: viewer)
    }
  end

  def serialize_comment(comment, viewer:)
    {
      id: comment.id,
      post_id: comment.post_id,
      parent_id: comment.parent_id,
      body: comment.body,
      created_at: comment.created_at.iso8601,
      updated_at: comment.updated_at.iso8601,
      likes_count: comment.likes.size,
      liked_by_current_user: comment.liked_by?(viewer),
      author: serialize_user(comment.user, viewer: viewer)
    }
  end

  def serialize_conversation(conversation, viewer:)
    other_participant = conversation.other_participant_for(viewer)
    latest_message = conversation.messages.max_by(&:created_at)
    participant = conversation.participant_for(viewer)

    {
      id: conversation.id,
      last_message_at: conversation.last_message_at&.iso8601,
      unread: latest_message.present? && participant.present? && latest_message.created_at > (participant.last_read_at || Time.at(0)),
      other_participant: other_participant ? serialize_user(other_participant, viewer: viewer) : nil,
      latest_message: latest_message ? serialize_message(latest_message, viewer: viewer) : nil
    }
  end

  def serialize_message(message, viewer:)
    {
      id: message.id,
      body: message.body,
      created_at: message.created_at.iso8601,
      updated_at: message.updated_at.iso8601,
      conversation_id: message.conversation_id,
      reply_to_message_id: message.reply_to_message_id,
      sender: serialize_user(message.user, viewer: viewer),
      from_current_user: message.user_id == viewer.id
    }
  end

  def serialize_notification(notification, viewer:)
    {
      id: notification.id,
      action: notification.action,
      message: notification.message,
      created_at: notification.created_at.iso8601,
      read_at: notification.read_at&.iso8601,
      actor: serialize_user(notification.actor, viewer: viewer),
      destination: notification_destination(notification)
    }
  end

  def attachment_url(attachment)
    return unless attachment&.attached?

    rails_blob_url(attachment, host: request.base_url)
  end

  def notification_destination(notification)
    case notification.notifiable
    when Post
      { kind: "post", id: notification.notifiable.id }
    when Comment
      { kind: "post", id: notification.notifiable.post_id, comment_id: notification.notifiable.id }
    when Follow
      { kind: "profile", username: notification.actor.username, user_id: notification.actor_id }
    when Message
      { kind: "conversation", id: notification.notifiable.conversation_id }
    else
      { kind: "home" }
    end
  end
end
