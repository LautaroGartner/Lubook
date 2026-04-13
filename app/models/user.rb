class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable, :timeoutable,
         :omniauthable, omniauth_providers: [ :github ]

  validates :username, presence: true, uniqueness: { case_sensitive: false },
            length: { in: 3..30 }, format: { with: /\A[a-zA-Z0-9_]+\z/ }

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.username = auth.info.nickname.presence || "user_#{SecureRandom.hex(4)}"
      user.skip_confirmation! # trust GitHub's email verification
    end
  end
end
