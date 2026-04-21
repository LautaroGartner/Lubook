class Message < ApplicationRecord
  belongs_to :conversation, touch: true
  belongs_to :user
  belongs_to :reply_to_message, class_name: "Message", optional: true
  has_one_attached :image

  validates :body, length: { maximum: 2000 }
  validate :body_or_image_present
  validate :acceptable_image
  validate :reply_to_message_in_same_conversation

  after_create_commit :update_conversation_activity!
  after_create_commit :mark_sender_as_read!
  after_create_commit :broadcast_to_other_participants!
  after_create_commit :broadcast_chat_badges!
  after_create_commit :broadcast_read_states!

  private

  def update_conversation_activity!
    conversation.update_column(:last_message_at, created_at)
  end

  def mark_sender_as_read!
    conversation.conversation_participants
                .where(user_id: user_id)
                .update_all(last_read_at: created_at, updated_at: Time.current)
  end

  def broadcast_to_other_participants!
    conversation.participants.where.not(id: user_id).each do |recipient|
      safe_broadcast_append_to(
        [ conversation, recipient ],
        target: "conversation_messages",
        partial: "messages/message",
        locals: { message: self, current_user_id: recipient.id }
      )
    end
  end

  def broadcast_chat_badges!
    conversation.participants.where.not(id: user_id).each do |recipient|
      safe_broadcast_replace_to(
        [ recipient, :chats ],
        target: "chat_badge",
        partial: "shared/chat_badge",
        locals: { count: recipient.unread_chats_count }
      )
    end
  end

  def broadcast_read_states!
    conversation.participants.each do |participant|
      safe_broadcast_replace_to(
        [ conversation, participant ],
        target: "chat_read_state",
        partial: "conversations/read_state",
        locals: {
          conversation: conversation,
          current_user: participant,
          other_participant: conversation.other_participant_for(participant)
        }
      )
    end
  end

  def safe_broadcast_append_to(*streamables, **options)
    broadcast_append_to(*streamables, **options)
  rescue ArgumentError => error
    Rails.logger.warn("[Turbo broadcast skipped] #{error.class}: #{error.message}")
  end

  def safe_broadcast_replace_to(*streamables, **options)
    Turbo::StreamsChannel.broadcast_replace_to(*streamables, **options)
  rescue ArgumentError => error
    Rails.logger.warn("[Turbo broadcast skipped] #{error.class}: #{error.message}")
  end

  def body_or_image_present
    return if body.present? || image.attached?

    errors.add(:base, "Add a message or a photo.")
  end

  def acceptable_image
    return unless image.attached?

    unless image.blob.content_type.in?(%w[image/png image/jpeg image/jpg image/gif image/webp image/heic image/heif image/svg+xml])
      errors.add(:image, "must be a PNG, JPG, GIF, WebP, HEIC, or SVG.")
    end

    return unless image.blob.byte_size > 10.megabytes

    errors.add(:image, "must be smaller than 10MB.")
  end

  def reply_to_message_in_same_conversation
    return unless reply_to_message_id.present?
    return if reply_to_message&.conversation_id == conversation_id

    errors.add(:reply_to_message, "must belong to the same conversation.")
  end
end
