class Comment < ApplicationRecord
  attr_accessor :reply_target_user_id

  belongs_to :user
  belongs_to :post, touch: true
  belongs_to :parent, class_name: "Comment", optional: true
  has_many :replies, -> { chronological.includes(user: { profile: { avatar_attachment: :blob } }) },
           class_name: "Comment", foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent
  has_many :likes, as: :likeable, dependent: :destroy

  validates :body, presence: true, length: { maximum: 2000 }
  validate :same_post_as_parent

  scope :chronological, -> { order(created_at: :asc) }
  scope :top_level, -> { where(parent_id: nil) }

  after_create_commit :create_notifications!

  def liked_by?(user)
    return false unless user
    likes.exists?(user_id: user.id)
  end

  def root_parent
    parent&.root_parent || self
  end

  def thread_root_id
    root_parent.id
  end

  def reply_target_user
    return @reply_target_user if defined?(@reply_target_user)

    @reply_target_user = User.find_by(id: reply_target_user_id)
  end

  private

  def same_post_as_parent
    return if parent.blank? || parent.post_id == post_id

    errors.add(:parent, "must belong to the same post")
  end

  def create_notifications!
    NotificationDispatcher.notify!(
      recipient: reply_target_user || parent&.user || post.user,
      actor: user,
      action: parent_id? ? "reply" : "comment",
      notifiable: self
    )
  end
end
