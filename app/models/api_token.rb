class ApiToken < ApplicationRecord
  EXPIRATION_WINDOW = 90.days

  belongs_to :user

  validates :name, presence: true, length: { maximum: 100 }
  validates :token_digest, presence: true, uniqueness: true

  scope :active, -> {
    where("expires_at IS NULL OR expires_at > ?", Time.current)
  }

  def self.issue_for!(user:, name:)
    raw_token = SecureRandom.hex(32)

    record = create!(
      user: user,
      name: name.presence || "iPhone",
      token_digest: digest(raw_token),
      expires_at: EXPIRATION_WINDOW.from_now,
      last_used_at: Time.current
    )

    [ record, raw_token ]
  end

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token.to_s)
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end
end
