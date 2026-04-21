class Like < ApplicationRecord
  belongs_to :user
  belongs_to :likeable, polymorphic: true, touch: true

  validates :user_id, uniqueness: { scope: [ :likeable_type, :likeable_id ] }

  after_create_commit :create_notification!

  private

  def create_notification!
    recipient = likeable.user if likeable.respond_to?(:user)
    action = likeable.is_a?(Post) ? "like_post" : "like_comment"

    NotificationDispatcher.notify!(
      recipient: recipient,
      actor: user,
      action: action,
      notifiable: likeable
    )
  end
end
