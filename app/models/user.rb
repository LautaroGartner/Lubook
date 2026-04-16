class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable, :timeoutable,
         :omniauthable, omniauth_providers: [ :github ]

  before_validation :normalize_username

  validates :username, presence: true, uniqueness: { case_sensitive: false },
          length: { in: 3..30 }, format: { with: /\A[a-zA-Z0-9_.]+\z/ }

  has_one  :profile,  dependent: :destroy
  has_many :posts,    dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes,    dependent: :destroy

  has_many :sent_follow_requests,
           class_name: "Follow", foreign_key: :requester_id, dependent: :destroy
  has_many :received_follow_requests,
           class_name: "Follow", foreign_key: :receiver_id, dependent: :destroy

  has_many :following, -> { where(follows: { status: Follow.statuses[:accepted] }) },
           through: :sent_follow_requests, source: :receiver
  has_many :followers, -> { where(follows: { status: Follow.statuses[:accepted] }) },
           through: :received_follow_requests, source: :requester

  after_create :build_default_profile

  def cached_followers_count
    Rails.cache.fetch([ self, "followers_count" ], expires_in: 5.minutes) do
      followers.count
    end
  end

  def cached_following_count
    Rails.cache.fetch([ self, "following_count" ], expires_in: 5.minutes) do
      following.count
    end
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.username = auth.info.nickname.presence || "user_#{SecureRandom.hex(4)}"
      user.skip_confirmation!
    end
  end

  private

  def normalize_username
    self.username = username.downcase.strip if username.present?
  end

  def build_default_profile
    create_profile!(display_name: username)
  end
end
