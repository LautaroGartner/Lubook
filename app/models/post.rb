class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :root_comments, -> { top_level.chronological.includes(:likes, user: { profile: { avatar_attachment: :blob } }) },
           class_name: "Comment"
  has_many :likes, as: :likeable, dependent: :destroy
  has_many_attached :images

  validates :body, presence: true, length: { maximum: 5000 }
  validate  :acceptable_images

  scope :recent, -> { order(created_at: :desc) }

  def liked_by?(user)
    return false unless user
    likes.exists?(user_id: user.id)
  end

  private

  def acceptable_images
    return unless images.attached?
    errors.add(:images, "max 10 per post") if images.count > 10
    images.each do |img|
      unless img.content_type.in?(%w[image/jpeg image/png image/webp image/gif])
        errors.add(:images, "must be JPEG, PNG, WEBP, or GIF")
      end
      errors.add(:images, "must be under 10MB") if img.byte_size > 10.megabytes
    end
  end
end
