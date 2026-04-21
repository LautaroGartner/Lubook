class Conversation < ApplicationRecord
  has_many :conversation_participants, dependent: :destroy
  has_many :participants, through: :conversation_participants, source: :user
  has_many :messages, dependent: :destroy

  scope :recent, -> { order(last_message_at: :desc, updated_at: :desc) }

  def self.direct_between!(user_a, user_b)
    participant_ids = [ user_a.id, user_b.id ].sort

    existing = joins(:conversation_participants)
      .group("conversations.id")
      .having("COUNT(*) = 2")
      .having("COUNT(*) FILTER (WHERE conversation_participants.user_id IN (?)) = 2", participant_ids)
      .first

    existing || create_with_participants!(user_a, user_b)
  end

  def other_participant_for(user)
    participants.where.not(id: user.id).first
  end

  def participant_for(user)
    conversation_participants.find_by(user: user)
  end

  private_class_method def self.create_with_participants!(user_a, user_b)
    transaction do
      conversation = create!
      conversation.conversation_participants.create!(user: user_a, last_read_at: Time.current)
      conversation.conversation_participants.create!(user: user_b)
      conversation
    end
  end
end
