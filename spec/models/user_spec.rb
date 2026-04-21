require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
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
      create(:follow, requester: follower, receiver: user, status: :accepted)

      expect(user.cached_followers_count).to eq(1)
    end

    it "ignores pending follow requests" do
      user = create(:user)
      follower = create(:user)
      create(:follow, requester: follower, receiver: user, status: :pending)

      expect(user.cached_followers_count).to eq(0)
    end
  end

  describe "#connected_users" do
    it "returns accepted follow connections without duplicates" do
      user = create(:user)
      following_user = create(:user)
      follower_user = create(:user)
      create(:follow, requester: user, receiver: following_user, status: :accepted)
      create(:follow, requester: follower_user, receiver: user, status: :accepted)
      create(:follow, requester: user, receiver: follower_user, status: :accepted)

      expect(user.connected_users).to match_array([ following_user, follower_user ])
    end
  end

  describe "#unread_notifications_count" do
    it "ignores message notifications" do
      user = create(:user)
      create(:notification, recipient: user, action: "message", notifiable: create(:message))

      expect(user.unread_notifications_count).to eq(0)
    end
  end

  describe "#unread_chats_count" do
    it "counts conversations with messages newer than the participant read time" do
      user = create(:user)
      other_user = create(:user)
      conversation = Conversation.create!(last_message_at: 5.minutes.ago)
      participant = create(:conversation_participant, conversation: conversation, user: user, last_read_at: 10.minutes.ago)
      create(:conversation_participant, conversation: conversation, user: other_user, last_read_at: 5.minutes.ago)

      expect(user.unread_chats_count).to eq(1)

      participant.update!(last_read_at: Time.current)
      expect(user.unread_chats_count).to eq(0)
    end
  end

  describe "#active_now?" do
    it "is true when the user has been active recently" do
      user = create(:user, last_active_at: 2.minutes.ago)

      expect(user.active_now?).to be(true)
    end

    it "is false when the user has been inactive for a while" do
      user = create(:user, last_active_at: 10.minutes.ago)

      expect(user.active_now?).to be(false)
    end
  end
end
