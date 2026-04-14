require "rails_helper"

RSpec.describe CommentPolicy do
  subject { described_class.new(user, comment) }

  let(:post_author) { create(:user) }
  let(:commenter) { create(:user) }
  let(:stranger) { create(:user) }
  let(:post) { create(:post, user: post_author) }
  let(:comment) { create(:comment, post: post, user: commenter) }

  context "when the user is the commenter" do
    let(:user) { commenter }
    it { is_expected.to permit_actions(%i[destroy]) }
  end

  context "when the user is the post author" do
    let(:user) { post_author }
    it { is_expected.to permit_actions(%i[destroy]) }
  end

  context "when the user is a stranger" do
    let(:user) { stranger }
    it { is_expected.to forbid_actions(%i[destroy]) }
  end
end
