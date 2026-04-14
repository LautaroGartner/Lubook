require "rails_helper"

RSpec.describe Profile, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "avatar validation" do
    it "rejects files larger than 5MB" do
      profile = build(:profile)
      profile.avatar.attach(
        io: StringIO.new("x" * 6.megabytes),
        filename: "big.jpg",
        content_type: "image/jpeg"
      )
      expect(profile).not_to be_valid
    end
  end
end
