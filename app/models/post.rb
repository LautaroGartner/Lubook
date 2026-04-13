class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy

  validates :body, presence: true, length: { maximum: 5000 }

  scope :recent, -> { order(created_at: :desc) }
end
