class Profile < ApplicationRecord
  belongs_to :user
  has_one_attached :avatar

  validates :display_name, length: { maximum: 80 }
  validates :bio,          length: { maximum: 500 }
  validates :location,     length: { maximum: 80 }

  validate :acceptable_avatar

  private

  def acceptable_avatar
    return unless avatar.attached?

    unless avatar.blob.byte_size <= 5.megabytes
      errors.add(:avatar, "must be under 5MB")
    end

    acceptable_types = %w[image/jpeg image/png image/webp image/gif]
    unless acceptable_types.include?(avatar.blob.content_type)
      errors.add(:avatar, "must be JPEG, PNG, WEBP, or GIF")
    end
  end
end
