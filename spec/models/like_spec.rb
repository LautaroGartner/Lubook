require "rails_helper"

RSpec.describe Like, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:likeable) }
  end

  describe "uniqueness" do
    it "prevents a user from liking the same post twice" do
      user = create(:user)
      post = create(:post)
      create(:like, user: user, likeable: post)
      duplicate = build(:like, user: user, likeable: post)
      expect(duplicate).not_to be_valid
    end

    it "allows different users to like the same post" do
      post = create(:post)
      create(:like, user: create(:user), likeable: post)
      second = build(:like, user: create(:user), likeable: post)
      expect(second).to be_valid
    end
  end

  describe "touching the likeable" do
    it "updates the post's updated_at when created" do
      post = create(:post)
      original_updated_at = post.updated_at
      travel 1.minute do
        create(:like, likeable: post)
        expect(post.reload.updated_at).to be > original_updated_at
      end
    end
  end
end
