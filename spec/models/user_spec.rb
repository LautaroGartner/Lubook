require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_uniqueness_of(:username).case_insensitive }
    it { is_expected.to validate_length_of(:username).is_at_least(3).is_at_most(30) }

    it "rejects usernames with invalid characters" do
      user = build(:user, username: "bad name!")
      expect(user).not_to be_valid
      expect(user.errors[:username]).to be_present
    end

    it "normalizes username to lowercase on save" do
      user = create(:user, username: "MixedCase")
      expect(user.reload.username).to eq("mixedcase")
    end
  end

  describe "associations" do
    it { is_expected.to have_one(:profile).dependent(:destroy) }
    it { is_expected.to have_many(:posts).dependent(:destroy) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
    it { is_expected.to have_many(:likes).dependent(:destroy) }
  end

  describe "callbacks" do
    it "creates a profile automatically after creation" do
      user = create(:user)
      expect(user.profile).to be_present
      expect(user.profile.display_name).to eq(user.username)
    end
  end

  describe "#cached_followers_count" do
    it "returns the number of accepted followers" do
      user = create(:user)
      follower = create(:user)
      create(:follow, :accepted, requester: follower, receiver: user)
      expect(user.cached_followers_count).to eq(1)
    end

    it "ignores pending follow requests" do
      user = create(:user)
      requester = create(:user)
      create(:follow, requester: requester, receiver: user) # default :pending
      expect(user.cached_followers_count).to eq(0)
    end
  end
end
