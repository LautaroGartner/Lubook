require "rails_helper"

RSpec.describe Follow, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:requester).class_name("User") }
    it { is_expected.to belong_to(:receiver).class_name("User") }
  end

  describe "enum status" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, accepted: 1) }
  end

  describe "validations" do
    it "prevents self-follows" do
      user = create(:user)
      follow = build(:follow, requester: user, receiver: user)
      expect(follow).not_to be_valid
      expect(follow.errors[:receiver]).to be_present
    end

    it "prevents duplicate follow requests" do
      requester = create(:user)
      receiver = create(:user)
      create(:follow, requester: requester, receiver: receiver)
      duplicate = build(:follow, requester: requester, receiver: receiver)
      expect(duplicate).not_to be_valid
    end
  end
end
