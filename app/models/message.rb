class Message < ApplicationRecord
  belongs_to :conversation, touch: true
  belongs_to :user

  validates :body, presence: true, length: { maximum: 2000 }

  after_create_commit :update_conversation_activity!
  after_create_commit :mark_sender_as_read!
  after_create_commit :broadcast_to_other_participants!
  after_create_commit :broadcast_chat_badges!

  private

  def update_conversation_activity!
    conversation.update_column(:last_message_at, created_at)
  end

  def mark_sender_as_read!
    conversation.conversation_participants.find_by(user_id: user_id)&.update(last_read_at: created_at)
  end

  def broadcast_to_other_participants!
    conversation.participants.where.not(id: user_id).find_each do |recipient|
      broadcast_append_to [ conversation, recipient ],
                          target: "conversation_messages",
                          partial: "messages/message",
                          locals: { message: self, current_user_id: recipient.id }
    end
  end

  def broadcast_chat_badges!
    conversation.participants.where.not(id: user_id).find_each do |recipient|
      Turbo::StreamsChannel.broadcast_replace_to(
        [ recipient, :chats ],
        target: "chat_badge",
        partial: "shared/chat_badge",
        locals: { count: recipient.unread_chats_count }
      )
    end
  end
end
