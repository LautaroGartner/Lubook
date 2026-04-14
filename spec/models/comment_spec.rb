require "rails_helper"

RSpec.describe Comment, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_most(2000) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:post) }
    it { is_expected.to have_many(:likes) }
  end

  describe "touching the post" do
    it "updates the post's updated_at when created" do
      post = create(:post)
      original_updated_at = post.updated_at
      travel 1.minute do
        create(:comment, post: post)
        expect(post.reload.updated_at).to be > original_updated_at
      end
    end
  end
end
