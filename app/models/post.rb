class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :root_comments, -> { top_level.chronological.includes(:likes, user: { profile: { avatar_attachment: :blob } }) },
           class_name: "Comment"
  has_many :likes, as: :likeable, dependent: :destroy
  has_one_attached :image

  validates :body, presence: true, length: { maximum: 5000 }
  validate  :acceptable_image

  scope :recent, -> { order(created_at: :desc) }

  def liked_by?(user)
    return false unless user
    likes.exists?(user_id: user.id)
  end

  private

  def acceptable_image
    return unless image.attached?

    unless image.blob.byte_size <= 10.megabytes
      errors.add(:image, "must be under 10MB")
    end

    acceptable_types = %w[image/jpeg image/png image/webp image/gif]
    unless acceptable_types.include?(image.blob.content_type)
      errors.add(:image, "must be JPEG, PNG, WEBP, or GIF")
    end
  end
end
