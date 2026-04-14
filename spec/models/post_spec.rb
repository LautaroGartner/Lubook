require "rails_helper"

RSpec.describe Post, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_most(5000) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
    it { is_expected.to have_many(:likes) }
  end

  describe "#liked_by?" do
    let(:user) { create(:user) }
    let(:post) { create(:post) }

    it "returns true when the user has liked it" do
      create(:like, user: user, likeable: post)
      expect(post.liked_by?(user)).to be true
    end

    it "returns false when the user has not liked it" do
      expect(post.liked_by?(user)).to be false
    end

    it "returns false for a nil user" do
      expect(post.liked_by?(nil)).to be false
    end
  end
end
