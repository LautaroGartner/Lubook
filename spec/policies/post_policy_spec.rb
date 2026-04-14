require "rails_helper"

RSpec.describe PostPolicy do
  subject { described_class.new(user, post) }

  let(:author) { create(:user) }
  let(:post) { create(:post, user: author) }

  context "when the user is the author" do
    let(:user) { author }
    it { is_expected.to permit_actions(%i[update destroy]) }
  end

  context "when the user is someone else" do
    let(:user) { create(:user) }
    it { is_expected.to forbid_actions(%i[update destroy]) }
  end

  context "when there is no user" do
    let(:user) { nil }
    it { is_expected.to forbid_actions(%i[update destroy]) }
  end
end
