class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post
  has_many :likes, as: :likeable, dependent: :destroy

  validates :body, presence: true, length: { maximum: 2000 }

  scope :chronological, -> { order(created_at: :asc) }

  def liked_by?(user)
    return false unless user
    likes.exists?(user_id: user.id)
  end
end
