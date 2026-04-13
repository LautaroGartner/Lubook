class Profile < ApplicationRecord
  belongs_to :user

  validates :display_name, length: { maximum: 80 }
  validates :bio,          length: { maximum: 500 }
  validates :location,     length: { maximum: 80 }
end
